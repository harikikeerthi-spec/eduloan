import { AuditService } from './audit.service';
export declare class AuditController {
    private readonly auditService;
    constructor(auditService: AuditService);
    getRecentActivity(limit: string): Promise<{
        success: boolean;
        data: {
            id: any;
            type: string;
            title: string;
            description: string;
            status: any;
            date: any;
            link: string;
        }[];
    }>;
}
