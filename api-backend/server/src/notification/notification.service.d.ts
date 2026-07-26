import { SupabaseService } from '../supabase/supabase.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
export declare class NotificationService {
    private readonly supabase;
    private readonly eventEmitter;
    private readonly logger;
    private get db();
    constructor(supabase: SupabaseService, eventEmitter: EventEmitter2);
    createNotification(userId: string, title: string, body: string, type: string, metadata?: any): Promise<any>;
    getNotificationsForUser(user: any, type?: string, limit?: number, offset?: number): Promise<{
        items: any[];
        total: number;
    }>;
    markAsRead(notificationId: string, user: any): Promise<any>;
    markAllAsRead(user: any): Promise<{
        success: boolean;
        count: number;
    }>;
    handleCandidateRegistered(payload: any): Promise<void>;
    handleApplicationCreated(payload: any): Promise<void>;
    handleApplicationSubmitted(payload: any): Promise<void>;
    handleDocumentUploaded(payload: any): Promise<void>;
    handleDocumentRejected(payload: any): Promise<void>;
    handleDocumentVerified(payload: any): Promise<void>;
}
