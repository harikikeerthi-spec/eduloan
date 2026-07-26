import { EventEmitter2 } from '@nestjs/event-emitter';
import { ChatService } from './chat.service';
import { S3Service } from '../document/s3.service';
import type { Response } from 'express';
export declare class ChatController {
    private readonly chatService;
    private readonly s3Service;
    private readonly eventEmitter;
    constructor(chatService: ChatService, s3Service: S3Service, eventEmitter: EventEmitter2);
    getConversations(req: any): Promise<any[]>;
    getMessages(conversationId: string): Promise<any[]>;
    connectToStaff(req: any): Promise<{
        success: boolean;
        conversation: any;
        whatsappUrl: string;
    }>;
    startConversationWithCustomer(req: any, body: {
        customerPhone: string;
        customerEmail?: string;
        customerName?: string;
        type?: string;
        bank?: string;
        applicationId?: string;
        applicationNumber?: string;
    }): Promise<{
        success: boolean;
        conversation: any;
    }>;
    startBankConversation(req: any, body: {
        bankName: string;
        bankEmail?: string;
        applicationId?: string;
        applicationNumber?: string;
    }): Promise<{
        success: boolean;
        error: string;
        conversation?: undefined;
    } | {
        success: boolean;
        conversation: any;
        error?: undefined;
    }>;
    uploadFile(req: any, file: Express.Multer.File, conversationId: string): Promise<{
        success: boolean;
        message: any;
    }>;
    getAttachment(messageId: string, res: Response): Promise<void>;
}
