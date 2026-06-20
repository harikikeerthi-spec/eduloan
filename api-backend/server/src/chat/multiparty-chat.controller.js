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
var MultiPartyChatController_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultiPartyChatController = void 0;
const common_1 = require("@nestjs/common");
const multiparty_chat_service_1 = require("./multiparty-chat.service");
const user_guard_1 = require("../auth/user.guard");
let MultiPartyChatController = MultiPartyChatController_1 = class MultiPartyChatController {
    multiPartyChatService;
    logger = new common_1.Logger(MultiPartyChatController_1.name);
    constructor(multiPartyChatService) {
        this.multiPartyChatService = multiPartyChatService;
    }
    async createMultiPartyConversation(req, body) {
        try {
            const conversation = await this.multiPartyChatService.getOrCreateMultiPartyConversation(body);
            return {
                success: true,
                data: conversation,
                message: 'Multi-party conversation created successfully',
            };
        }
        catch (error) {
            this.logger.error('Failed to create multi-party conversation', error);
            throw new common_1.HttpException('Failed to create conversation', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getMyConversations(req) {
        try {
            const conversations = await this.multiPartyChatService.getUserConversations(req.user.email);
            return {
                success: true,
                data: conversations,
            };
        }
        catch (error) {
            throw new common_1.HttpException('Failed to fetch conversations', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getConversationDetails(conversationId) {
        try {
            const [messages, documents, participants] = await Promise.all([
                this.multiPartyChatService.getConversationMessages(conversationId),
                this.multiPartyChatService.getConversationDocuments(conversationId),
                this.multiPartyChatService.getConversationParticipants(conversationId),
            ]);
            return {
                success: true,
                data: {
                    messages,
                    documents,
                    participants,
                },
            };
        }
        catch (error) {
            throw new common_1.HttpException('Failed to fetch conversation details', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getConversationMessages(conversationId, req) {
        try {
            const messages = await this.multiPartyChatService.getConversationMessages(conversationId, req.user.email);
            return {
                success: true,
                data: messages,
            };
        }
        catch (error) {
            throw new common_1.HttpException('Failed to fetch messages', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async sendMessage(conversationId, req, body) {
        try {
            const message = await this.multiPartyChatService.saveMultiPartyMessage({
                conversationId,
                senderEmail: req.user.email,
                senderName: `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim(),
                senderRole: req.user.role,
                content: body.content,
                messageType: 'text',
                recipientEmails: body.recipientEmails,
            });
            return {
                success: true,
                data: message,
                message: 'Message sent successfully',
            };
        }
        catch (error) {
            this.logger.error('Failed to send message', error);
            throw new common_1.HttpException('Failed to send message', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async shareDocument(conversationId, req, body) {
        try {
            const docShare = await this.multiPartyChatService.shareDocument({
                conversationId,
                applicationId: body.applicationId,
                documentId: body.documentId,
                documentName: body.documentName,
                documentType: body.documentType,
                uploadedByEmail: req.user.email,
                uploaderRole: req.user.role,
            });
            return {
                success: true,
                data: docShare,
                message: 'Document shared successfully',
            };
        }
        catch (error) {
            this.logger.error('Failed to share document', error);
            throw new common_1.HttpException('Failed to share document', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getSharedDocuments(conversationId) {
        try {
            const documents = await this.multiPartyChatService.getConversationDocuments(conversationId);
            return {
                success: true,
                data: documents,
            };
        }
        catch (error) {
            throw new common_1.HttpException('Failed to fetch documents', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async addParticipant(conversationId, body) {
        try {
            const participant = await this.multiPartyChatService.addParticipant({
                conversationId,
                email: body.email,
                fullName: body.fullName,
                role: body.role,
            });
            return {
                success: true,
                data: participant,
                message: 'Participant added successfully',
            };
        }
        catch (error) {
            this.logger.error('Failed to add participant', error);
            throw new common_1.HttpException('Failed to add participant', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getParticipants(conversationId) {
        try {
            const participants = await this.multiPartyChatService.getConversationParticipants(conversationId);
            return {
                success: true,
                data: participants,
            };
        }
        catch (error) {
            throw new common_1.HttpException('Failed to fetch participants', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async notifyByEmail(conversationId, req, body) {
        try {
            if (!['staff', 'admin', 'super_admin', 'bank', 'partner_bank'].includes(req.user.role)) {
                throw new common_1.HttpException('Unauthorized', common_1.HttpStatus.FORBIDDEN);
            }
            const emailSent = await this.multiPartyChatService.notifyParticipantOfMessage({
                recipientEmail: body.recipientEmail,
                senderName: `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim(),
                senderRole: req.user.role,
                messageContent: body.messageContent,
                conversationTopic: body.conversationTopic,
                applicationNumber: body.applicationNumber,
                bank: body.bank,
            });
            return {
                success: emailSent,
                message: emailSent ? 'Email sent successfully' : 'Failed to send email',
            };
        }
        catch (error) {
            this.logger.error('Failed to send notification email', error);
            throw new common_1.HttpException('Failed to send email', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
};
exports.MultiPartyChatController = MultiPartyChatController;
__decorate([
    (0, common_1.Post)('multiparty/create'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "createMultiPartyConversation", null);
__decorate([
    (0, common_1.Get)('conversations/my'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "getMyConversations", null);
__decorate([
    (0, common_1.Get)('multiparty/:conversationId/details'),
    __param(0, (0, common_1.Param)('conversationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "getConversationDetails", null);
__decorate([
    (0, common_1.Get)('multiparty/:conversationId/messages'),
    __param(0, (0, common_1.Param)('conversationId')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "getConversationMessages", null);
__decorate([
    (0, common_1.Post)('multiparty/:conversationId/message'),
    __param(0, (0, common_1.Param)('conversationId')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "sendMessage", null);
__decorate([
    (0, common_1.Post)('multiparty/:conversationId/share-document'),
    __param(0, (0, common_1.Param)('conversationId')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "shareDocument", null);
__decorate([
    (0, common_1.Get)('multiparty/:conversationId/documents'),
    __param(0, (0, common_1.Param)('conversationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "getSharedDocuments", null);
__decorate([
    (0, common_1.Post)('multiparty/:conversationId/participant'),
    __param(0, (0, common_1.Param)('conversationId')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "addParticipant", null);
__decorate([
    (0, common_1.Get)('multiparty/:conversationId/participants'),
    __param(0, (0, common_1.Param)('conversationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "getParticipants", null);
__decorate([
    (0, common_1.Post)('multiparty/:conversationId/notify-email'),
    __param(0, (0, common_1.Param)('conversationId')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], MultiPartyChatController.prototype, "notifyByEmail", null);
exports.MultiPartyChatController = MultiPartyChatController = MultiPartyChatController_1 = __decorate([
    (0, common_1.Controller)('chat'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __metadata("design:paramtypes", [multiparty_chat_service_1.MultiPartyChatService])
], MultiPartyChatController);
//# sourceMappingURL=multiparty-chat.controller.js.map