"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var ChatService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let ChatService = ChatService_1 = class ChatService {
    supabase;
    logger = new common_1.Logger(ChatService_1.name);
    constructor(supabase) {
        this.supabase = supabase;
    }
    get db() {
        return this.supabase.getClient();
    }
    normalizePhone(phoneStr) {
        if (phoneStr.startsWith('BNK_'))
            return phoneStr;
        const cleaned = phoneStr.replace('whatsapp:', '').trim().replace(/\D/g, '');
        if (cleaned.length > 10 && cleaned.startsWith('91')) {
            return cleaned.substring(2);
        }
        if (cleaned.length > 10) {
            return cleaned.slice(-10);
        }
        return cleaned;
    }
    async getOrCreateConversation(customerPhone, customerEmail, conversationType = 'staff', customerName, bankName, additionalMetadata) {
        if (!customerPhone) {
            throw new common_1.HttpException('A valid phone number is required to start a chat. Please update your profile.', common_1.HttpStatus.BAD_REQUEST);
        }
        const phone = this.normalizePhone(customerPhone);
        let query = this.db
            .from('Conversation')
            .select('*')
            .eq('customerPhone', phone);
        if (additionalMetadata && additionalMetadata.applicationId) {
            query = query.contains('metadata', { applicationId: additionalMetadata.applicationId });
        }
        let { data: convData, error } = await query.order('updatedAt', { ascending: false }).limit(1);
        let conv = convData?.[0] || null;
        if (error) {
            this.logger.error('Failed to query conversation', error);
            throw new common_1.HttpException('Database error', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
        const mergedMetadata = {
            type: conversationType,
            bank: bankName || null,
            ...(additionalMetadata || {})
        };
        if (!conv) {
            const { data: newConv, error: createError } = await this.db
                .from('Conversation')
                .insert({
                customerPhone: phone,
                status: 'active',
                customerEmail: customerEmail || null,
                customerName: customerName || null,
                metadata: mergedMetadata
            })
                .select()
                .single();
            if (createError) {
                this.logger.error('Failed to create conversation', createError);
                throw new common_1.HttpException('Database error', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
            }
            conv = newConv;
        }
        else {
            const updateData = {
                status: 'active',
                updatedAt: new Date().toISOString(),
                metadata: {
                    ...(conv.metadata || {}),
                    ...mergedMetadata
                }
            };
            if (customerEmail)
                updateData.customerEmail = customerEmail;
            if (customerName)
                updateData.customerName = customerName;
            const { data: updatedConv, error: updateError } = await this.db
                .from('Conversation')
                .update(updateData)
                .eq('id', conv.id)
                .select()
                .single();
            if (updateError) {
                this.logger.error('Failed to reactivate conversation', updateError);
                throw new common_1.HttpException('Database error reactivating conversation', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
            }
            conv = updatedConv;
        }
        return conv;
    }
    async saveMessage(data) {
        const { data: message, error } = await this.db
            .from('Message')
            .insert({
            ...data,
            messageType: data.messageType || 'text',
            status: data.status || 'sent'
        })
            .select()
            .single();
        if (error) {
            this.logger.error('Failed to save message', error);
            throw new common_1.HttpException('Database error saving message', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
        await this.db
            .from('Conversation')
            .update({ updatedAt: new Date().toISOString() })
            .eq('id', data.conversationId);
        return message;
    }
    async getConversations(status = 'active', user) {
        let query = this.db
            .from('Conversation')
            .select(`
          id, customerPhone, customerEmail, customerName, metadata, status, updatedAt, createdAt,
          Message (id, content, senderType, createdAt, status)
      `)
            .eq('status', status)
            .order('updatedAt', { ascending: false });
        if (user && (user.role === 'bank' || user.role === 'partner_bank')) {
            query = query.contains('metadata', { type: 'bank' });
            const bankName = user.bankName || (user.firstName && user.firstName.includes('Bank') ? user.firstName : null);
            if (bankName) {
                query = query.contains('metadata', { bank: bankName });
            }
        }
        else if (user && user.role === 'agent') {
            query = query.contains('metadata', { type: 'agent' });
        }
        const { data, error } = await query;
        if (error) {
            throw new common_1.HttpException('Db Error', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
        return data.map((conv) => ({
            ...conv,
            lastMessage: conv.Message && conv.Message.length > 0
                ? conv.Message.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())[0]
                : null
        }));
    }
    async getMessages(conversationId) {
        const { data, error } = await this.db
            .from('Message')
            .select('*')
            .eq('conversationId', conversationId)
            .order('createdAt', { ascending: true });
        if (error) {
            throw new common_1.HttpException('Db Error', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
        return data;
    }
    async getMessageById(messageId) {
        const { data, error } = await this.db
            .from('Message')
            .select('*')
            .eq('id', messageId)
            .maybeSingle();
        if (error) {
            throw new common_1.HttpException('Db Error', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
        return data;
    }
    async getMessagesByPhone(phone) {
        const cleanPhone = this.normalizePhone(phone);
        const { data: convData } = await this.db
            .from('Conversation')
            .select('id')
            .eq('customerPhone', cleanPhone)
            .eq('status', 'active')
            .order('updatedAt', { ascending: false })
            .limit(1);
        const conv = convData?.[0] || null;
        if (!conv)
            return [];
        return this.getMessages(conv.id);
    }
};
exports.ChatService = ChatService;
exports.ChatService = ChatService = ChatService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], ChatService);
//# sourceMappingURL=chat.service.js.map