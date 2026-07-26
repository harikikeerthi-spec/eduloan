import { SupabaseService } from '../supabase/supabase.service';
import { EmailService } from '../auth/email.service';
export declare class UniversityInquiryService {
    private supabase;
    private emailService;
    private get db();
    constructor(supabase: SupabaseService, emailService: EmailService);
    createInquiry(data: {
        userId?: string;
        name: string;
        email: string;
        mobile: string;
        universityName: string;
        type: string;
    }): Promise<any>;
    getInquiriesByUser(userId: string): Promise<any[]>;
    checkInquiry(email: string, universityName: string, type: string): Promise<{
        exists: boolean;
    }>;
    private sendInquiryEmails;
}
