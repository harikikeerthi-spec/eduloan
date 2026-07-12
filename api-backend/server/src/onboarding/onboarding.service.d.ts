import { SupabaseService } from '../supabase/supabase.service';
import { EmailService } from '../auth/email.service';
export declare class OnboardingService {
    private supabase;
    private emailService;
    private get db();
    constructor(supabase: SupabaseService, emailService: EmailService);
    saveOnboardingData(data: any, userId?: string): Promise<{
        success: boolean;
        message: string;
        user?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        user: any;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        error: any;
        user?: undefined;
    }>;
    shareOnboardingLink(studentId: string, studentEmail: string, studentName: string, shareUrl: string, staffUser: any): Promise<{
        success: boolean;
        message: string;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        error: any;
    }>;
}
