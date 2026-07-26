import { SupabaseService } from '../supabase/supabase.service';
import { UsersService } from '../users/users.service';
import { AuditLogService } from '../auth/audit-log.service';
import { S3Service } from '../document/s3.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { EmailService } from '../auth/email.service';
export declare class StaffProfileService {
    private supabase;
    private usersService;
    private auditLog;
    private s3Service;
    private eventEmitter;
    private emailService;
    private get db();
    constructor(supabase: SupabaseService, usersService: UsersService, auditLog: AuditLogService, s3Service: S3Service, eventEmitter: EventEmitter2, emailService: EmailService);
    createProfile(staffUser: any, body: {
        linked_user_id: string;
        target_bank?: string;
        loan_type?: string;
        internal_notes?: string;
    }): Promise<any>;
    listProfiles(staffUser: any, query: {
        search?: string;
        bankStatus?: string;
    }): Promise<any[]>;
    getProfile(profileId: string): Promise<any>;
    getProfileByLinkedUserId(linkedUserId: string): Promise<any>;
    fetchUserDocuments(profileId: string, staffUser: any): Promise<{
        fetched: number;
        documents: any[];
        skipped: number;
    }>;
    uploadStaffDocument(profileId: string, staffUser: any, file: Express.Multer.File, body: {
        doc_type: string;
        description?: string;
    }): Promise<any>;
    updateDocumentStatus(profileId: string, docId: string, staffUser: any, body: {
        status: string;
        rejection_reason?: string;
    }): Promise<{
        document: any;
        sync: string;
    }>;
    shareWithBank(profileId: string, staffUser: any, body: {
        doc_ids: string[];
        bank_name: string;
        bank_email: string;
        expires_in_days?: number;
        access_note?: string;
    }): Promise<{
        share_id: any;
        token: string;
        share_url: string;
        expires_at: string;
        documents_shared: number;
    }>;
    getProfileDocuments(profileId: string): Promise<any[]>;
    getShareHistory(profileId: string): Promise<any[]>;
    removeDocument(profileId: string, docId: string, staffUser: any): Promise<{
        success: boolean;
    }>;
    logDashboardActivity(user: any, data: {
        type: string;
        msg: string;
        icon: string;
        color: string;
    }): Promise<void>;
    getDashboardActivities(limit?: number): Promise<{
        id: any;
        type: any;
        msg: any;
        icon: any;
        color: any;
        actorName: any;
        actorEmail: any;
        createdAt: any;
    }[]>;
    getAllDashboardActivities(opts: {
        limit: number;
        offset: number;
        type?: string;
        search?: string;
    }): Promise<{
        items: {
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
    private formatDashboardActivity;
    private parseDate;
    private mapOnboardingToApplication;
    shareProfile(studentId: string, staffUser: any, body: {
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
    }>;
    private generateApplicationNumber;
    getTodayDashboard(user: any): Promise<{
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
    }>;
    getDashboardSummary(): Promise<{
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
    }>;
    getRejectionAnalytics(period: string): Promise<{
        reason: string;
        count: number;
        percentage: number;
    }[]>;
    getSlaTracker(): Promise<{
        complianceRate: number;
        averageTat: number;
        stages: {
            name: string;
            tatDays: number;
            compliance: number;
        }[];
    }>;
    globalSearch(q: string): Promise<any[]>;
    getAiPredictionScore(applicationId: string): Promise<{
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
    }>;
    getDeadlineCalendar(): Promise<any[]>;
}
