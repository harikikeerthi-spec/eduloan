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
var ChatGateway_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
const common_1 = require("@nestjs/common");
const chat_service_1 = require("./chat.service");
const twilio_service_1 = require("./twilio.service");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const event_emitter_1 = require("@nestjs/event-emitter");
let ChatGateway = ChatGateway_1 = class ChatGateway {
    chatService;
    twilioService;
    jwtService;
    configService;
    server;
    logger = new common_1.Logger(ChatGateway_1.name);
    onlineUsers = new Map();
    constructor(chatService, twilioService, jwtService, configService) {
        this.chatService = chatService;
        this.twilioService = twilioService;
        this.jwtService = jwtService;
        this.configService = configService;
    }
    async handleConnection(client) {
        try {
            const token = client.handshake.auth.token || client.handshake.headers['authorization']?.split(' ')[1];
            const isSimulator = client.handshake.auth.simulator === true;
            const simPhone = client.handshake.auth.phone;
            if (isSimulator && simPhone) {
                const cleanPhone = String(simPhone).replace('whatsapp:', '');
                client.join(`sim_${cleanPhone}`);
                this.logger.log(`Simulator connected for phone: ${cleanPhone}`);
                return;
            }
            if (!token) {
                throw new Error('No token provided');
            }
            const payload = await this.jwtService.verifyAsync(token, {
                secret: this.configService.get('JWT_SECRET')
            });
            client.data.user = payload;
            this.logger.log(`Client connected: ${client.id} (User: ${payload.email}, Role: ${payload.role})`);
            if (payload.role === 'admin' || payload.role === 'staff' || payload.role === 'super_admin') {
                client.join('room_staff');
            }
            else if (payload.role === 'bank' || payload.role === 'partner_bank') {
                client.join('room_bank');
            }
            const userId = payload.id || payload.uid || payload.sub;
            if (userId) {
                client.join(`user_${userId}`);
            }
            if (payload.email) {
                this.onlineUsers.set(client.id, payload.email.toLowerCase());
                this.server.to('room_staff').emit('presence_update', Array.from(new Set(this.onlineUsers.values())));
            }
        }
        catch (error) {
            this.logger.warn(`Connection rejected: ${client.id} - ${error.message}`);
            client.disconnect();
        }
    }
    handleDisconnect(client) {
        this.logger.log(`Client disconnected: ${client.id}`);
        const email = this.onlineUsers.get(client.id);
        if (email) {
            this.onlineUsers.delete(client.id);
            this.server.to('room_staff').emit('presence_update', Array.from(new Set(this.onlineUsers.values())));
        }
    }
    handleJoinRoom(client, room) {
        const user = client.data.user;
        const isStaff = user?.role === 'admin' || user?.role === 'staff' || user?.role === 'super_admin';
        const isBank = user?.role === 'bank' || user?.role === 'partner_bank';
        if ((room === 'room_staff' && isStaff) || (room === 'room_bank' && isBank)) {
            client.join(room);
            this.logger.log(`Client ${client.id} explicitly joined ${room}`);
        }
        return { success: true };
    }
    handleRequestPresence(client) {
        client.emit('presence_update', Array.from(new Set(this.onlineUsers.values())));
        return { success: true };
    }
    handleJoinConversation(client, conversationId) {
        client.join(`conv_${conversationId}`);
        return { status: 'joined', conversationId };
    }
    handleLeaveConversation(client, conversationId) {
        client.leave(`conv_${conversationId}`);
        return { status: 'left', conversationId };
    }
    async handleSendMessage(client, payload) {
        const user = client.data.user;
        const senderType = user.role || 'staff';
        try {
            const msg = await this.chatService.saveMessage({
                conversationId: payload.conversationId,
                senderType,
                senderId: user.email || user.sub,
                receiverType: 'customer',
                content: payload.content,
                status: 'sent'
            });
            this.server.to(`conv_${payload.conversationId}`).emit('new_message', msg);
            if (user.role === 'bank' || user.role === 'partner_bank') {
                this.server.to('room_bank').emit('conversation_updated', {
                    conversationId: payload.conversationId,
                    lastMessage: msg
                });
            }
            else {
                this.server.to('room_staff').emit('conversation_updated', {
                    conversationId: payload.conversationId,
                    lastMessage: msg
                });
            }
            const cleanPhone = payload.customerPhone.replace('whatsapp:', '');
            this.server.to(`sim_${cleanPhone}`).emit('wa_message_received', msg);
            if (payload.customerPhone) {
                await this.twilioService.sendWhatsAppMessage(payload.customerPhone, payload.content).catch(e => {
                    this.logger.error('Twilio Error (ignoring for simulation): ' + e.message);
                });
            }
            return { success: true, message: msg };
        }
        catch (e) {
            this.logger.error('Failed to process outgoing message', e);
            return { success: false, error: e.message };
        }
    }
    async handleSimReply(client, payload) {
        try {
            const from = payload.phone.startsWith('whatsapp:') ? payload.phone : `whatsapp:${payload.phone}`;
            const conversation = await this.chatService.getOrCreateConversation(from);
            const msg = await this.chatService.saveMessage({
                conversationId: conversation.id,
                senderType: 'customer',
                senderId: payload.phone.replace('whatsapp:', ''),
                content: payload.content,
                status: 'delivered'
            });
            this.server.to(`conv_${conversation.id}`).emit('new_message', msg);
            const type = conversation.metadata?.type || 'staff';
            if (type === 'bank') {
                this.server.to('room_bank').emit('conversation_updated', {
                    conversationId: conversation.id,
                    lastMessage: msg
                });
            }
            else {
                this.server.to('room_staff').emit('conversation_updated', {
                    conversationId: conversation.id,
                    lastMessage: msg
                });
            }
            return { success: true, message: msg };
        }
        catch (e) {
            this.logger.error('Simulator reply failed', e);
            return { success: false, error: e.message };
        }
    }
    handleUserLogin(payload) {
        this.logger.log(`Broadcasting login alert for ${payload.email} to staff`);
        if (this.server) {
            this.server.to('room_staff').emit('user_activity', {
                id: Date.now(),
                type: payload.isNewUser ? 'registration' : 'login',
                msg: `${payload.firstName || 'Student'} ${payload.lastName || ''} logged in.`,
                time: 'Just now',
                color: 'bg-emerald-50 text-emerald-700 border-emerald-100',
                icon: 'login',
                actorName: `${payload.firstName || 'Student'} ${payload.lastName || ''}`.trim() || payload.email,
                actorEmail: payload.email,
                createdAt: new Date().toISOString()
            });
        }
        else {
            this.logger.warn(`WS server not initialized. Skipping user.login broadcast.`);
        }
    }
    handleDashboardActivity(payload) {
        this.logger.log(`Broadcasting dashboard activity: ${payload.msg}`);
        if (this.server) {
            this.server.to('room_staff').emit('user_activity', {
                id: payload.id || Date.now(),
                type: payload.type || 'info',
                msg: payload.msg,
                time: payload.time || 'Just now',
                icon: payload.icon || 'history',
                color: payload.color || 'bg-slate-50 text-slate-600 border-slate-100',
                actorName: payload.actorName || 'System',
                actorEmail: payload.actorEmail || null,
                createdAt: payload.createdAt || new Date().toISOString()
            });
        }
        else {
            this.logger.warn(`WS server not initialized. Skipping dashboard.activity broadcast.`);
        }
    }
    handleNotificationCreated(payload) {
        this.logger.log(`Broadcasting notification alert: ${payload.title} to User ID: ${payload.userId}`);
        if (this.server) {
            if (payload.userId === 'staff' || payload.userId === 'system') {
                this.server.to('room_staff').emit('notification_received', payload);
            }
            else if (payload.userId === 'bank') {
                this.server.to('room_bank').emit('notification_received', payload);
            }
            else {
                this.server.to(`user_${payload.userId}`).emit('notification_received', payload);
            }
        }
        else {
            this.logger.warn(`WS server not initialized. Skipping notification broadcast.`);
        }
    }
};
exports.ChatGateway = ChatGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], ChatGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('joinRoom'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, String]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleJoinRoom", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('request_presence'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleRequestPresence", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('join_conversation'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, String]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleJoinConversation", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('leave_conversation'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, String]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleLeaveConversation", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('send_message'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleSendMessage", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('sim_customer_reply'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleSimReply", null);
__decorate([
    (0, event_emitter_1.OnEvent)('user.login'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleUserLogin", null);
__decorate([
    (0, event_emitter_1.OnEvent)('dashboard.activity'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleDashboardActivity", null);
__decorate([
    (0, event_emitter_1.OnEvent)('notification.created'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleNotificationCreated", null);
exports.ChatGateway = ChatGateway = ChatGateway_1 = __decorate([
    (0, websockets_1.WebSocketGateway)({
        cors: {
            origin: '*',
        },
        namespace: '/chat'
    }),
    __metadata("design:paramtypes", [chat_service_1.ChatService,
        twilio_service_1.TwilioService,
        jwt_1.JwtService,
        config_1.ConfigService])
], ChatGateway);
//# sourceMappingURL=chat.gateway.js.map