import { SupabaseService } from '../supabase/supabase.service';
import { DigilockerService } from '../integration/digilocker.service';
import { DocumentVerificationService } from '../ai/services/document-verification.service';
import { ApplicationReviewService } from '../ai/services/application-review.service';
import { EmailService } from '../auth/email.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
export declare class ApplicationService {
    private supabase;
    private digilockerService;
    private verificationService;
    private applicationReviewService;
    private emailService;
    private eventEmitter;
    private get db();
    constructor(supabase: SupabaseService, digilockerService: DigilockerService, verificationService: DocumentVerificationService, applicationReviewService: ApplicationReviewService, emailService: EmailService, eventEmitter: EventEmitter2);
    private parseDate;
    private validateApplicationConstraints;
    createApplication(userId: string, data: any): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    submitApplication(applicationId: string, userId: string): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getApplicationById(applicationId: string): Promise<any>;
    getApplicationByNumber(applicationNumber: string): Promise<any>;
    getUserApplications(userId: string, filters?: {
        status?: string;
        loanType?: string;
        limit?: number;
        offset?: number;
    }): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
        };
    }>;
    updateApplication(applicationId: string, userId: string, data: any): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    adminUpdateApplication(applicationId: string, data: any): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    cancelApplication(applicationId: string, userId: string, reason?: string): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getApplicationTracking(applicationId: string, userId?: string): Promise<{
        success: boolean;
        data: {
            applicationId: any;
            applicationNumber: any;
            status: any;
            currentStage: any;
            progress: any;
            stages: {
                key: string;
                label: string;
                order: number;
                isCompleted: boolean;
                isCurrent: boolean;
                completedAt: any;
            }[];
            timeline: any;
            documents: {
                total: any;
                pending: any;
                verified: any;
                rejected: any;
            };
            estimatedCompletion: any;
            submittedAt: any;
            lastUpdated: any;
        };
    }>;
    trackApplication(applicationNumber: string): Promise<{
        success: boolean;
        data: {
            stages: {
                key: string;
                label: string;
                order: number;
                isCompleted: boolean;
                isCurrent: boolean;
            }[];
            id: any;
            applicationNumber: any;
            loanType: any;
            bank: any;
            amount: any;
            status: any;
            stage: any;
            progress: any;
            submittedAt: any;
            estimatedCompletionAt: any;
            updatedAt: any;
        };
    }>;
    private normalizeLoanType;
    private initializeRequiredDocuments;
    uploadDocument(applicationId: string, userId: string, documentData: {
        docType: string;
        docName: string;
        fileName: string;
        filePath: string;
        fileSize?: number;
        mimeType?: string;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getApplicationDocuments(applicationId: string, userId?: string): Promise<{
        success: boolean;
        data: any[];
        grouped: {
            pending: any[];
            verified: any[];
            rejected: any[];
            notUploaded: any[];
            vault: any[];
        };
        summary: {
            total: number;
            vaultTotal: number;
            uploaded: number;
            pending: number;
            verified: number;
            rejected: number;
            notUploaded: number;
        };
    }>;
    syncApplicationDocuments(applicationId: string, adminId?: string): Promise<{
        success: boolean;
        message: string;
        syncedCount: number;
    }>;
    deleteDocument(documentId: string, userId: string): Promise<{
        success: boolean;
        message: string;
    }>;
    getAllApplications(filters?: {
        status?: string;
        stage?: string;
        loanType?: string;
        bank?: string;
        search?: string;
        fromDate?: string;
        toDate?: string;
        limit?: number;
        offset?: number;
        sortBy?: string;
        sortOrder?: 'asc' | 'desc';
        userId?: string;
        excludeStatus?: string;
    }): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
        };
        message?: undefined;
    } | {
        success: boolean;
        data: never[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
        };
        message: string;
    }>;
    updateApplicationStatus(applicationId: string, adminId: string, adminName: string, data: {
        status?: string;
        stage?: string;
        progress?: number;
        remarks?: string;
        rejectionReason?: string;
        bank?: string;
    }, role?: string): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    verifyDocument(documentId: string, adminId: string, data: {
        status: 'verified' | 'rejected';
        rejectionReason?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data?: undefined;
    } | {
        success: boolean;
        data: any;
        message: string;
    }>;
    addApplicationNote(applicationId: string, authorId: string, authorName: string, data: {
        content: string;
        type?: string;
        isInternal?: boolean;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getApplicationNotes(applicationId: string, includeInternal?: boolean): Promise<{
        success: boolean;
        data: any[];
    }>;
    getApplicationStats(user?: any, bankId?: string): Promise<{
        success: boolean;
        data: {
            total: any;
            totalAmount: number;
            disbursedAmount: number;
            statusStats: Record<string, number>;
            loanTypeStats: {
                type: string;
                count: number;
                totalAmount: number;
            }[];
            recentApplications: any;
            monthlyComparison: {
                thisMonth: any;
                lastMonth: any;
                change: string;
            };
        };
    }>;
    aiReviewApplication(applicationId: string, adminId: string, adminName: string): Promise<{
        success: boolean;
        data: import("../ai/services/application-review.service").ApplicationReviewResult;
        message: string;
    }>;
    private generateApplicationNumber;
    private createStatusHistory;
    getAgentApplications(agentId: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getAgentStats(agentId: string): Promise<{
        success: boolean;
        data: {
            total: number;
            totalAmount: number;
            revenue: number;
            disbursedAmount: number;
            recentApplications: any[];
        };
    }>;
    shareApplication(applicationId: string, adminId: string, adminName: string): Promise<{
        success: boolean;
        message: string;
    }>;
    getRequiredDocuments(loanType: string): {
        success: boolean;
        data: {
            docType: string;
            docName: string;
            isRequired: boolean;
        }[] | {
            docType: string;
            docName: string;
            isRequired: boolean;
        }[] | {
            docType: string;
            docName: string;
            isRequired: boolean;
        }[] | {
            docType: string;
            docName: string;
            isRequired: boolean;
        }[] | {
            docType: string;
            docName: string;
            isRequired: boolean;
        }[];
    };
    getApplicationStages(): {
        success: boolean;
        data: {
            application_submitted: {
                order: number;
                label: string;
                progress: number;
            };
            document_verification: {
                order: number;
                label: string;
                progress: number;
            };
            credit_check: {
                order: number;
                label: string;
                progress: number;
            };
            bank_review: {
                order: number;
                label: string;
                progress: number;
            };
            sanction: {
                order: number;
                label: string;
                progress: number;
            };
            disbursement: {
                order: number;
                label: string;
                progress: number;
            };
        };
    };
}
