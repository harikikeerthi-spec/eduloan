import { SupabaseService } from '../supabase/supabase.service';
export type AppUser = {
    id: string;
    email: string;
    firstName?: string;
    lastName?: string;
    role?: string;
    [key: string]: any;
};
export declare class AuditLogService {
    private supabase;
    private get db();
    constructor(supabase: SupabaseService);
    logAction(action: string, entityType: string, entityId: string, user: AppUser, changes: any, request?: any): Promise<void>;
    getEntityLogs(entityType: string, entityId: string, limit?: number): Promise<{
        id: any;
        action: any;
        initiatedBy: any;
        changes: any;
        createdAt: any;
        initiator: {
            firstName: any;
            lastName: any;
            email: any;
        }[];
    }[]>;
    getAllLogs(entityType?: string, initiatedBy?: string, limit?: number, offset?: number): Promise<{
        id: any;
        action: any;
        entityType: any;
        entityId: any;
        createdAt: any;
        initiator: {
            firstName: any;
            lastName: any;
            email: any;
        }[];
    }[]>;
}
