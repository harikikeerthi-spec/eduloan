import { ConfigService } from '@nestjs/config';
export declare class EmailService {
    private configService;
    private readonly logger;
    private transporter;
    constructor(configService: ConfigService);
    private initializeTransporter;
    sendChatNotificationEmail(to: string, senderName: string, senderRole: string, message: string, conversationContext: {
        applicationNumber?: string;
        customerName?: string;
        bank?: string;
        subject: string;
    }): Promise<boolean>;
    sendDocumentNotificationEmail(to: string, documentDetails: {
        documentName: string;
        uploadedBy: string;
        uploadedByRole: string;
        applicationNumber: string;
        bank?: string;
        status: string;
    }): Promise<boolean>;
    private escapeHtml;
}
