import { ConfigService } from '@nestjs/config';
export interface StudentNotificationPayload {
    name: string;
    mobile: string;
    whatsapp_consent: boolean;
}
export interface NotificationResult {
    channel: 'whatsapp' | 'sms' | 'mock';
    sid: string;
    status: string;
}
export declare class StudentNotificationService {
    private readonly configService;
    private readonly logger;
    private client;
    constructor(configService: ConfigService);
    sendStudentNotification(student: StudentNotificationPayload): Promise<NotificationResult>;
    private sendWhatsApp;
    private sendSMS;
}
