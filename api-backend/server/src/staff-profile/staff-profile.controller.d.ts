import { StaffProfileService } from './staff-profile.service';
export declare class StaffProfileController {
    private readonly svc;
    constructor(svc: StaffProfileService);
    list(req: any, search?: string, bankStatus?: string): Promise<{
        success: boolean;
        data: any[];
        total: number;
    }>;
    create(req: any, body: {
        linked_user_id: string;
        target_bank?: string;
        loan_type?: string;
        internal_notes?: string;
    }): Promise<{
        success: boolean;
        data: any;
    }>;
    checkExists(userId: string): Promise<{
        success: boolean;
        exists: boolean;
        data: any;
    }>;
    getOne(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    fetchDocs(id: string, req: any): Promise<{
        fetched: number;
        documents: any[];
        skipped: number;
        success: boolean;
    }>;
    getDocs(id: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    uploadDoc(id: string, req: any, file: Express.Multer.File, docType: string, description?: string): Promise<{
        success: boolean;
        data: any;
    }>;
    updateStatus(id: string, docId: string, req: any, body: {
        status: string;
        rejection_reason?: string;
    }): Promise<{
        success: boolean;
        data: {
            document: any;
            sync: string;
        };
    }>;
    removeDoc(id: string, docId: string, req: any): Promise<{
        success: boolean;
    }>;
    share(id: string, req: any, body: {
        doc_ids: string[];
        bank_name: string;
        bank_email: string;
        expires_in_days?: number;
        access_note?: string;
    }): Promise<{
        success: boolean;
        data: {
            share_id: any;
            token: string;
            share_url: string;
            expires_at: string;
            documents_shared: number;
        };
    }>;
    shareProfile(studentId: string, req: any, body: {
        recipientType: string;
        recipientName: string;
        recipientEmail: string;
        message?: string;
        sharedBy?: string;
        studentDetails?: any;
    }): Promise<{
        shareId: any;
        token: string;
        url: string;
        expiresAt: string;
        documentsShared: number;
        success: boolean;
    }>;
    getShares(id: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    logActivity(req: any, body: {
        type: string;
        msg: string;
        icon: string;
        color: string;
    }): Promise<{
        success: boolean;
    }>;
    getActivities(limit?: string): Promise<{
        success: boolean;
        data: {
            id: any;
            type: any;
            msg: any;
            icon: any;
            color: any;
            actorName: any;
            actorEmail: any;
            createdAt: any;
        }[];
    }>;
    getAllActivities(limit?: string, offset?: string, type?: string, search?: string): Promise<{
        success: boolean;
        data: {
            id: any;
            type: any;
            msg: any;
            icon: any;
            color: any;
            actorName: any;
            actorEmail: any;
            createdAt: any;
        }[];
        total: number;
    }>;
    getTodayDashboard(req: any): Promise<{
        success: boolean;
        data: {
            urgent: {
                count: number;
                items: any[];
            };
            newFiles: {
                count: number;
                items: any[];
            };
            respondedQueries: {
                count: number;
                items: any[];
            };
            pendingDisbursements: {
                count: number;
                items: any[];
            };
            pendingDecisions: {
                count: number;
                items: any[];
            };
        };
    }>;
    getDashboardSummary(): Promise<{
        success: boolean;
        data: {
            counts: {
                total?: undefined;
                pending?: undefined;
                sanctioned?: undefined;
                rejected?: undefined;
            };
            conversionRate: number;
            avgTatDays: number;
            pipelineValue: number;
            monthlyTrend: never[];
        } | {
            counts: {
                total: number;
                pending: number;
                sanctioned: number;
                rejected: number;
            };
            conversionRate: number;
            avgTatDays: number;
            pipelineValue: any;
            monthlyTrend: {
                month: string;
                count: number;
                value: number;
            }[];
        };
    }>;
    getRejectionAnalytics(period?: string): Promise<{
        success: boolean;
        data: {
            reason: string;
            count: number;
            percentage: number;
        }[];
    }>;
    getSlaTracker(): Promise<{
        success: boolean;
        data: {
            complianceRate: number;
            averageTat: number;
            stages: {
                name: string;
                tatDays: number;
                compliance: number;
            }[];
        };
    }>;
    globalSearch(q?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getAiPredictionScore(id: string): Promise<{
        success: boolean;
        data: {
            applicationId: string;
            predictionScore: number;
            riskLevel: string;
            approvedProbabilityPercent: number;
            rulesRun: {
                rule: string;
                passed: boolean;
                scoreDelta: number;
                details: string;
            }[];
            educationAbroad: {
                isForeign: boolean;
                destinationCountry: any;
                autoFlagged: boolean;
                additionalDocumentsNeeded: string[];
                forexParametersEnabled: boolean;
                exchangeRateBufferPercent: number;
            };
        };
    }>;
    getDeadlineCalendar(): Promise<{
        success: boolean;
        data: any[];
    }>;
}
