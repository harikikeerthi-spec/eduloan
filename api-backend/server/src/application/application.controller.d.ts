import type { Response } from 'express';
import { ApplicationService } from './application.service';
export declare class ApplicationController {
    private applicationService;
    constructor(applicationService: ApplicationService);
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
    getRequiredDocuments(loanType: string): Promise<{
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
    }>;
    getApplicationStages(): Promise<{
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
    }>;
    createApplication(req: any, body: any): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getMyApplications(req: any, status?: string, loanType?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
        };
    }>;
    getAllApplications(status?: string, stage?: string, loanType?: string, bank?: string, search?: string, fromDate?: string, toDate?: string, limit?: string, offset?: string, sortBy?: string, sortOrder?: string, userId?: string, excludeStatus?: string): Promise<{
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
    getApplicationStats(req: any, bankId?: string): Promise<{
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
    getDocumentsAdmin(id: string): Promise<{
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
    syncVaultDocuments(id: string): Promise<{
        success: boolean;
        message: string;
        syncedCount: number;
    }>;
    updateApplicationDetails(id: string, body: any): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    updateApplicationStatus(req: any, id: string, body: {
        status?: string;
        stage?: string;
        progress?: number;
        remarks?: string;
        rejectionReason?: string;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    aiReviewApplication(req: any, id: string): Promise<{
        success: boolean;
        data: import("../ai/services/application-review.service").ApplicationReviewResult;
        message: string;
    }>;
    shareApplication(req: any, id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    viewDocumentAdmin(applicationId: string, documentId: string, res: Response): Promise<void | Response<any, Record<string, any>>>;
    verifyDocument(req: any, documentId: string, body: {
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
    getTrackingAdmin(id: string): Promise<{
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
    getApplicationNotes(id: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    addApplicationNote(req: any, id: string, body: {
        content: string;
        type?: string;
        isInternal?: boolean;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getAgentStats(req: any): Promise<{
        success: boolean;
        data: {
            total: number;
            totalAmount: number;
            revenue: number;
            disbursedAmount: number;
            recentApplications: any[];
        };
    }>;
    getAgentApplications(req: any): Promise<{
        success: boolean;
        data: any[];
    }>;
    getApplicationById(req: any, id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getApplicationTracking(req: any, id: string): Promise<{
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
    updateApplication(req: any, id: string, body: any): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    submitApplication(req: any, id: string): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    cancelApplication(req: any, id: string, body: {
        reason?: string;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getApplicationDocuments(req: any, id: string): Promise<{
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
    uploadDocument(req: any, applicationId: string, file: Express.Multer.File, docType: string, docName: string): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    deleteDocument(req: any, applicationId: string, documentId: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
