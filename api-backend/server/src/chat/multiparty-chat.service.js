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
var MultiPartyChatService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultiPartyChatService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const email_service_1 = require("./email.service");
let MultiPartyChatService = MultiPartyChatService_1 = class MultiPartyChatService {
    supabase;
    emailService;
    logger = new common_1.Logger(MultiPartyChatService_1.name);
    constructor(supabase, emailService) {
        this.supabase = supabase;
        this.emailService = emailService;
    }
    get db() {
        return this.supabase.getClient();
    }
    async getOrCreateMultiPartyConversation(data) {
        try {
            let { data: existing } = await this.db
                .from('Conversation')
                .select('id')
                .eq('applicationId', data.applicationId)
                .eq('isMultiParty', true)
                .maybeSingle();
            if (existing) {
                return existing;
            }
            const { data: conversation, error: convError } = await this.db
                .from('Conversation')
                .insert({
                applicationId: data.applicationId,
                isMultiParty: true,
                conversationTopic: data.topic,
                metadata: { type: 'multiparty' },
                status: 'active',
            })
                .select()
                .single();
            if (convError)
                throw convError;
            const participants = [
                ...data.customers.map((c) => ({ ...c, role: 'customer' })),
                ...(data.staffMembers || []).map((s) => ({ ...s, role: 'staff' })),
                ...(data.bankMembers || []).map((b) => ({ ...b, role: 'bank' })),
            ];
            for (const participant of participants) {
                await this.db
                    .from('Conversation_Participant')
                    .insert({
                    conversationId: conversation.id,
                    email: participant.email,
                    fullName: participant.fullName,
                    role: participant.role,
                    canShare: true,
                })
                    .single();
            }
            return conversation;
        }
        catch (error) {
            this.logger.error('Failed to create multi-party conversation', error);
            throw error;
        }
    }
    async saveMultiPartyMessage(data) {
        try {
            const { data: conversation } = await this.db
                .from('Conversation')
                .select('*')
                .eq('id', data.conversationId)
                .single();
            let recipients = data.recipientEmails;
            if (!recipients || recipients.length === 0) {
                const { data: participants } = await this.db
                    .from('Conversation_Participant')
                    .select('email, role')
                    .eq('conversationId', data.conversationId);
                recipients = participants?.map((p) => p.email) || [];
            }
            const { data: message, error: msgError } = await this.db
                .from('Message')
                .insert({
                conversationId: data.conversationId,
                senderType: data.senderRole,
                senderId: data.senderEmail,
                content: data.content,
                messageType: data.messageType || 'text',
                status: 'sent',
                recipientEmails: recipients,
            })
                .select()
                .single();
            if (msgError)
                throw msgError;
            for (const email of recipients) {
                const { data: participant } = await this.db
                    .from('Conversation_Participant')
                    .select('role')
                    .eq('conversationId', data.conversationId)
                    .eq('email', email)
                    .single();
                await this.db
                    .from('Message_Recipient')
                    .insert({
                    messageId: message.id,
                    recipientEmail: email,
                    recipientRole: participant?.role || 'unknown',
                    status: 'delivered',
                });
            }
            await this.db
                .from('Conversation')
                .update({ updatedAt: new Date().toISOString() })
                .eq('id', data.conversationId);
            return message;
        }
        catch (error) {
            this.logger.error('Failed to save multi-party message', error);
            throw error;
        }
    }
    async shareDocument(data) {
        try {
            const { data: participants } = await this.db
                .from('Conversation_Participant')
                .select('email, role, fullName')
                .eq('conversationId', data.conversationId);
            const sharedEmails = participants?.map((p) => p.email) || [];
            const sharedRoles = [...new Set(participants?.map((p) => p.role) || [])];
            const { data: docShare, error: shareError } = await this.db
                .from('Document_Share')
                .insert({
                conversationId: data.conversationId,
                applicationId: data.applicationId,
                documentId: data.documentId,
                documentName: data.documentName,
                documentType: data.documentType,
                uploadedBy: data.uploadedByEmail,
                uploaderRole: data.uploaderRole,
                sharedWith: sharedEmails,
                sharedWithRoles: sharedRoles,
                status: 'active',
            })
                .select()
                .single();
            if (shareError)
                throw shareError;
            await this.saveMultiPartyMessage({
                conversationId: data.conversationId,
                senderEmail: 'system@vidyaloan.com',
                senderName: 'VidyaLoan System',
                senderRole: 'system',
                content: `📄 Document shared: ${data.documentName}`,
                messageType: 'document_share',
                recipientEmails: sharedEmails,
            });
            const uploader = participants?.find((p) => p.email === data.uploadedByEmail);
            for (const participant of participants || []) {
                if (participant.email !== data.uploadedByEmail) {
                    const emailSent = await this.emailService.sendDocumentNotificationEmail(participant.email, {
                        documentName: data.documentName,
                        uploadedBy: uploader?.fullName || data.uploadedByEmail,
                        uploadedByRole: data.uploaderRole,
                        applicationNumber: data.applicationId,
                        status: 'Shared',
                    });
                    await this.db.from('Email_Log').insert({
                        recipientEmail: participant.email,
                        subject: `Document Shared: ${data.documentName}`,
                        documentShareId: docShare.id,
                        status: emailSent ? 'sent' : 'failed',
                    });
                }
            }
            return docShare;
        }
        catch (error) {
            this.logger.error('Failed to share document', error);
            throw error;
        }
    }
    async addParticipant(data) {
        try {
            const { data: participant, error } = await this.db
                .from('Conversation_Participant')
                .insert({
                conversationId: data.conversationId,
                email: data.email,
                fullName: data.fullName,
                role: data.role,
                canShare: true,
            })
                .select()
                .single();
            if (error)
                throw error;
            await this.saveMultiPartyMessage({
                conversationId: data.conversationId,
                senderEmail: 'system@vidyaloan.com',
                senderName: 'VidyaLoan System',
                senderRole: 'system',
                content: `✅ ${data.fullName} (${data.role}) joined the conversation`,
                messageType: 'participant_joined',
            });
            return participant;
        }
        catch (error) {
            this.logger.error('Failed to add participant', error);
            throw error;
        }
    }
    async getConversationMessages(conversationId, userEmail) {
        try {
            const { data: messages } = await this.db
                .from('Message')
                .select(`
          *,
          Message_Recipient (
            recipientEmail,
            recipientRole,
            status,
            readAt
          )
        `)
                .eq('conversationId', conversationId)
                .order('createdAt', { ascending: true });
            return messages || [];
        }
        catch (error) {
            this.logger.error('Failed to get conversation messages', error);
            throw error;
        }
    }
    async getConversationDocuments(conversationId) {
        try {
            const { data: documents } = await this.db
                .from('Document_Share')
                .select('*')
                .eq('conversationId', conversationId)
                .order('createdAt', { ascending: false });
            return documents || [];
        }
        catch (error) {
            this.logger.error('Failed to get conversation documents', error);
            throw error;
        }
    }
    async getUserConversations(userEmail) {
        try {
            const { data: participations } = await this.db
                .from('Conversation_Participant')
                .select(`
          conversationId,
          Conversation (
            id,
            applicationId,
            conversationTopic,
            isMultiParty,
            status,
            updatedAt,
            metadata
          )
        `)
                .eq('email', userEmail)
                .eq('isActive', true);
            return participations?.map((p) => p.Conversation) || [];
        }
        catch (error) {
            this.logger.error('Failed to get user conversations', error);
            throw error;
        }
    }
    async getConversationParticipants(conversationId) {
        try {
            const { data: participants } = await this.db
                .from('Conversation_Participant')
                .select('*')
                .eq('conversationId', conversationId)
                .eq('isActive', true)
                .order('joinedAt', { ascending: false });
            return participants || [];
        }
        catch (error) {
            this.logger.error('Failed to get conversation participants', error);
            throw error;
        }
    }
    async notifyParticipantOfMessage(data) {
        try {
            const emailSent = await this.emailService.sendChatNotificationEmail(data.recipientEmail, data.senderName, data.senderRole, data.messageContent, {
                applicationNumber: data.applicationNumber,
                subject: data.conversationTopic,
                bank: data.bank,
            });
            if (emailSent) {
                await this.db.from('Email_Log').insert({
                    recipientEmail: data.recipientEmail,
                    subject: `New Message: ${data.conversationTopic}`,
                    status: 'sent',
                });
            }
            return emailSent;
        }
        catch (error) {
            this.logger.error('Failed to send notification email', error);
            return false;
        }
    }
};
exports.MultiPartyChatService = MultiPartyChatService;
exports.MultiPartyChatService = MultiPartyChatService = MultiPartyChatService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        email_service_1.EmailService])
], MultiPartyChatService);
//# sourceMappingURL=multiparty-chat.service.js.map