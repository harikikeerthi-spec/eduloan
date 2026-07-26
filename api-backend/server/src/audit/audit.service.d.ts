import { SupabaseService } from '../supabase/supabase.service';
export declare class AuditService {
    private supabase;
    private get db();
    constructor(supabase: SupabaseService);
    getRecentActivity(limit?: number): Promise<{
        id: any;
        type: string;
        title: string;
        description: string;
        status: any;
        date: any;
        link: string;
    }[]>;
}
