import { NotificationService } from './notification.service';
export declare class NotificationController {
    private readonly notificationService;
    constructor(notificationService: NotificationService);
    getNotifications(req: any, type?: string, limit?: string, offset?: string): Promise<{
        items: any[];
        total: number;
        success: boolean;
    }>;
    markRead(id: string, req: any): Promise<{
        success: boolean;
        data: any;
    }>;
    markAllRead(req: any): Promise<{
        success: boolean;
        count: number;
    }>;
}
