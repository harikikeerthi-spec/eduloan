"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var WhatsappController_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.WhatsappController = void 0;
const common_1 = require("@nestjs/common");
const chat_service_1 = require("./chat.service");
const chat_gateway_1 = require("./chat.gateway");
const twilio = __importStar(require("twilio"));
let WhatsappController = WhatsappController_1 = class WhatsappController {
    chatService;
    chatGateway;
    logger = new common_1.Logger(WhatsappController_1.name);
    constructor(chatService, chatGateway) {
        this.chatService = chatService;
        this.chatGateway = chatGateway;
    }
    healthCheck() {
        return {
            status: 'ok',
            message: 'WhatsApp webhook endpoint is active',
            routes: {
                primary: 'POST /api/webhook/whatsapp',
                alias: 'POST /api/whatsapp',
                history: 'GET  /api/whatsapp/history/:phone',
            },
            note: 'Set one of the above POST URLs in Twilio Console → Sandbox Settings → "When a message comes in"'
        };
    }
    async handleIncomingMessage(req, res, body) {
        this.logger.log('━━━━━━━━━━ TWILIO WEBHOOK RECEIVED ━━━━━━━━━━');
        this.logger.log(`Content-Type : ${req.headers['content-type']}`);
        this.logger.log(`Raw body keys: ${Object.keys(body || {}).join(', ')}`);
        this.logger.log(`From         : ${body?.From}`);
        this.logger.log(`To           : ${body?.To}`);
        this.logger.log(`Body         : ${body?.Body}`);
        this.logger.log(`MessageSid   : ${body?.MessageSid}`);
        this.logger.log(`NumMedia     : ${body?.NumMedia}`);
        this.logger.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        const from = body?.From;
        const content = body?.Body;
        const mediaUrl = body?.MediaUrl0;
        const messageSid = body?.MessageSid;
        if (!from) {
            this.logger.error('[WEBHOOK] Missing "From" field — body may not be parsed (urlencoded issue?)');
            this.logger.error(`Full body dump: ${JSON.stringify(body)}`);
            return res.status(400).send('Missing From field');
        }
        if (!content && !mediaUrl) {
            this.logger.warn('[WEBHOOK] No Body or MediaUrl0 in payload — ignoring');
            const twiml = new twilio.twiml.MessagingResponse();
            return res.type('text/xml').send(twiml.toString());
        }
        try {
            const conversation = await this.chatService.getOrCreateConversation(from);
            this.logger.log(`[WEBHOOK] Conversation ID: ${conversation.id} | Phone: ${conversation.customerPhone}`);
            const msg = await this.chatService.saveMessage({
                conversationId: conversation.id,
                senderType: 'customer',
                senderId: conversation.customerPhone,
                receiverType: 'system',
                content: content || '[Media Attachment]',
                messageType: mediaUrl ? 'image' : 'text',
                status: 'delivered'
            });
            this.logger.log(`[WEBHOOK] Message saved with ID: ${msg.id}`);
            if (this.chatGateway.server) {
                this.chatGateway.server.to(`conv_${conversation.id}`).emit('new_message', msg);
                this.logger.log(`[WEBHOOK] Emitted 'new_message' to conv_${conversation.id}`);
                const type = conversation.metadata?.type || 'staff';
                const room = type === 'bank' ? 'room_bank' : 'room_staff';
                this.chatGateway.server.to(room).emit('conversation_updated', {
                    conversationId: conversation.id,
                    lastMessage: msg
                });
                this.logger.log(`[WEBHOOK] Emitted 'conversation_updated' to ${room}`);
            }
            else {
                this.logger.warn('[WEBHOOK] WebSocket server not initialized — real-time update skipped');
            }
            const twiml = new twilio.twiml.MessagingResponse();
            this.logger.log('[WEBHOOK] Responding to Twilio with 200 OK (empty TwiML)');
            return res.type('text/xml').send(twiml.toString());
        }
        catch (error) {
            this.logger.error('[WEBHOOK] Failed to process incoming WhatsApp message:', error?.message);
            this.logger.error(error);
            return res.status(200).send('<?xml version="1.0" encoding="UTF-8"?><Response></Response>');
        }
    }
    async getHistory(phone) {
        return this.chatService.getMessagesByPhone(phone);
    }
};
exports.WhatsappController = WhatsappController;
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], WhatsappController.prototype, "healthCheck", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Res)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object, Object]),
    __metadata("design:returntype", Promise)
], WhatsappController.prototype, "handleIncomingMessage", null);
__decorate([
    (0, common_1.Get)('history/:phone'),
    __param(0, (0, common_1.Param)('phone')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], WhatsappController.prototype, "getHistory", null);
exports.WhatsappController = WhatsappController = WhatsappController_1 = __decorate([
    (0, common_1.Controller)(['webhook/whatsapp', 'whatsapp']),
    __metadata("design:paramtypes", [chat_service_1.ChatService,
        chat_gateway_1.ChatGateway])
], WhatsappController);
//# sourceMappingURL=whatsapp.controller.js.map