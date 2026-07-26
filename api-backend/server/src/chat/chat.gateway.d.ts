import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { TwilioService } from './twilio.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
export declare class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private readonly chatService;
    private readonly twilioService;
    private readonly jwtService;
    private readonly configService;
    server: Server;
    private readonly logger;
    private onlineUsers;
    constructor(chatService: ChatService, twilioService: TwilioService, jwtService: JwtService, configService: ConfigService);
    handleConnection(client: Socket): Promise<void>;
    handleDisconnect(client: Socket): void;
    handleJoinRoom(client: Socket, room: string): {
        success: boolean;
    };
    handleRequestPresence(client: Socket): {
        success: boolean;
    };
    handleJoinConversation(client: Socket, conversationId: string): {
        status: string;
        conversationId: string;
    };
    handleLeaveConversation(client: Socket, conversationId: string): {
        status: string;
        conversationId: string;
    };
    handleSendMessage(client: Socket, payload: {
        conversationId: string;
        customerPhone: string;
        content: string;
    }): Promise<{
        success: boolean;
        message: any;
        error?: undefined;
    } | {
        success: boolean;
        error: any;
        message?: undefined;
    }>;
    handleSimReply(client: Socket, payload: {
        phone: string;
        content: string;
    }): Promise<{
        success: boolean;
        message: any;
        error?: undefined;
    } | {
        success: boolean;
        error: any;
        message?: undefined;
    }>;
    handleUserLogin(payload: any): void;
    handleDashboardActivity(payload: any): void;
    handleNotificationCreated(payload: any): void;
}
