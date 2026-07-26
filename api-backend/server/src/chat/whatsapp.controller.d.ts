import type { Request, Response } from 'express';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
export declare class WhatsappController {
    private readonly chatService;
    private readonly chatGateway;
    private readonly logger;
    constructor(chatService: ChatService, chatGateway: ChatGateway);
    healthCheck(): {
        status: string;
        message: string;
        routes: {
            primary: string;
            alias: string;
            history: string;
        };
        note: string;
    };
    handleIncomingMessage(req: Request, res: Response, body: any): Promise<Response<any, Record<string, any>>>;
    getHistory(phone: string): Promise<any[]>;
}
