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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const event_emitter_1 = require("@nestjs/event-emitter");
const chat_service_1 = require("./chat.service");
const user_guard_1 = require("../auth/user.guard");
const s3_service_1 = require("../document/s3.service");
const multer_1 = require("multer");
const storage = (0, multer_1.memoryStorage)();
let ChatController = class ChatController {
    chatService;
    s3Service;
    eventEmitter;
    constructor(chatService, s3Service, eventEmitter) {
        this.chatService = chatService;
        this.s3Service = s3Service;
        this.eventEmitter = eventEmitter;
    }
    async getConversations(req) {
        return this.chatService.getConversations('active', req.user);
    }
    async getMessages(conversationId) {
        return this.chatService.getMessages(conversationId);
    }
    async connectToStaff(req) {
        const user = req.user;
        const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim();
        const conversation = await this.chatService.getOrCreateConversation(user.phoneNumber, user.email, 'staff', fullName || undefined);
        const rawNumber = process.env.TWILIO_WHATSAPP_NUMBER || '+14155238886';
        const cleanNumber = rawNumber.replace('whatsapp:', '').replace(/\D/g, '');
        return {
            success: true,
            conversation,
            whatsappUrl: `https://wa.me/${cleanNumber}?text=Hi Vidyaloan team, I am ${user.firstName} and I would like to connect with a mentor.`
        };
    }
    async startConversationWithCustomer(req, body) {
        const conversationType = body.type || (req.user.role === 'bank' || req.user.role === 'partner_bank' ? 'bank' : 'staff');
        const bankName = body.bank || (req.user.role === 'bank' ? req.user.firstName : null);
        const additionalMetadata = {};
        if (body.applicationId)
            additionalMetadata.applicationId = body.applicationId;
        if (body.applicationNumber)
            additionalMetadata.applicationNumber = body.applicationNumber;
        const conversation = await this.chatService.getOrCreateConversation(body.customerPhone, body.customerEmail, conversationType, body.customerName, bankName, additionalMetadata);
        return {
            success: true,
            conversation
        };
    }
    async startBankConversation(req, body) {
        if (!body.bankName) {
            return { success: false, error: 'bankName is required' };
        }
        const safeBank = body.bankName.toUpperCase().replace(/[^A-Z0-9]/g, '_');
        const syntheticPhone = body.applicationId
            ? `BNK_${safeBank}_APP_${body.applicationId}`
            : `BNK_${safeBank}`;
        const shortAppId = body.applicationNumber || (body.applicationId ? body.applicationId.slice(0, 8) : '');
        const displayName = body.applicationId
            ? `${body.bankName} - App #${shortAppId}`
            : `${body.bankName} (Bank)`;
        const conversation = await this.chatService.getOrCreateConversation(syntheticPhone, body.bankEmail || `bank+${safeBank.toLowerCase()}@internal`, 'bank', displayName, body.bankName, {
            applicationId: body.applicationId || null,
            applicationNumber: body.applicationNumber || null,
        });
        return {
            success: true,
            conversation
        };
    }
    async uploadFile(req, file, conversationId) {
        if (!file)
            throw new common_1.BadRequestException('File is required');
        if (!conversationId)
            throw new common_1.BadRequestException('conversationId is required');
        const user = req.user;
        const senderType = user.role || 'staff';
        const senderId = user.email || user.sub;
        const senderName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || undefined;
        const s3Key = `chat_attachments/${conversationId}/${Date.now()}_${file.originalname}`;
        let attachmentUrl = '';
        try {
            await this.s3Service.upload(s3Key, file.buffer, file.mimetype);
            attachmentUrl = s3Key;
        }
        catch (s3Error) {
            console.warn(`[CHAT UPLOAD] S3 Upload failed: ${s3Error.message}. Falling back to local storage.`);
            try {
                const fs = require('fs');
                const path = require('path');
                const localDir = path.join(process.cwd(), 'uploads', 'chat', conversationId);
                fs.mkdirSync(localDir, { recursive: true });
                fs.writeFileSync(path.join(localDir, file.originalname), file.buffer);
                attachmentUrl = `local:${conversationId}/${file.originalname}`;
            }
            catch (err) {
                throw new common_1.BadRequestException('Failed to store file');
            }
        }
        const isImage = file.mimetype.startsWith('image/');
        const msg = await this.chatService.saveMessage({
            conversationId,
            senderType,
            senderId,
            senderName,
            content: file.originalname,
            messageType: isImage ? 'image' : 'document',
            status: 'sent',
            attachmentUrl,
            attachmentType: file.mimetype
        });
        this.eventEmitter.emit('chat.message_created', msg);
        return { success: true, message: msg };
    }
    async getAttachment(messageId, res) {
        const msg = await this.chatService.getMessageById(messageId);
        if (!msg || !msg.attachmentUrl) {
            throw new common_1.NotFoundException('Attachment not found');
        }
        if (msg.attachmentUrl.startsWith('local:')) {
            const [, relativePath] = msg.attachmentUrl.split('local:');
            const fs = require('fs');
            const path = require('path');
            const filePath = path.join(process.cwd(), 'uploads', 'chat', relativePath);
            if (fs.existsSync(filePath)) {
                return res.sendFile(filePath);
            }
            else {
                throw new common_1.NotFoundException('Local file not found');
            }
        }
        try {
            const presignedUrl = await this.s3Service.getPresignedUrl(msg.attachmentUrl, 3600);
            return res.redirect(302, presignedUrl);
        }
        catch (err) {
            console.error('[CHAT ATTACHMENT] Failed to generate presigned URL:', err);
            throw new common_1.NotFoundException('Unable to retrieve attachment from storage.');
        }
    }
};
exports.ChatController = ChatController;
__decorate([
    (0, common_1.Get)('conversations'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ChatController.prototype, "getConversations", null);
__decorate([
    (0, common_1.Get)('messages/:conversationId'),
    __param(0, (0, common_1.Param)('conversationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ChatController.prototype, "getMessages", null);
__decorate([
    (0, common_1.Post)('connect'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ChatController.prototype, "connectToStaff", null);
__decorate([
    (0, common_1.Post)('staff-start'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ChatController.prototype, "startConversationWithCustomer", null);
__decorate([
    (0, common_1.Post)('bank-start'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ChatController.prototype, "startBankConversation", null);
__decorate([
    (0, common_1.Post)('upload'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('file', {
        storage,
        limits: { fileSize: 25 * 1024 * 1024 },
        fileFilter: (req, file, cb) => {
            const ext = file.originalname.split('.').pop()?.toLowerCase();
            const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx'];
            const isMimeValid = file.mimetype.match(/\/(jpg|jpeg|png|pdf|msword|vnd.openxmlformats-officedocument.wordprocessingml.document|vnd.ms-excel|vnd.openxmlformats-officedocument.spreadsheetml.sheet)$/) || file.mimetype === 'application/octet-stream';
            const isExtValid = ext && allowedExtensions.includes(ext);
            if (isMimeValid || isExtValid) {
                cb(null, true);
            }
            else {
                cb(new common_1.BadRequestException('Unsupported file type for chat attachment'), false);
            }
        },
    })),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.UploadedFile)()),
    __param(2, (0, common_1.Body)('conversationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object, String]),
    __metadata("design:returntype", Promise)
], ChatController.prototype, "uploadFile", null);
__decorate([
    (0, common_1.Get)('attachment/:messageId'),
    __param(0, (0, common_1.Param)('messageId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], ChatController.prototype, "getAttachment", null);
exports.ChatController = ChatController = __decorate([
    (0, common_1.Controller)('chat'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __metadata("design:paramtypes", [chat_service_1.ChatService,
        s3_service_1.S3Service,
        event_emitter_1.EventEmitter2])
], ChatController);
//# sourceMappingURL=chat.controller.js.map