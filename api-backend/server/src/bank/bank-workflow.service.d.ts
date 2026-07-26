import { SupabaseService } from '../supabase/supabase.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
export interface BankWorkflowConfig {
    maxQueryRetries: number;
    queryResponseDays: number;
    processingFeeDays: number;
    disbursementDays: number;
}
export declare class BankWorkflowService {
    private readonly db;
    private readonly eventEmitter;
    constructor(db: SupabaseService, eventEmitter: EventEmitter2);
    submitApplicationToBank(applicationId: string, bankId: string, bankName: string, submittedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    logFile(submissionId: string, lanNumber: string, loggedBy: string, notes?: string): Promise<{
        success: boolean;
        data: any;
    }>;
    moveToUnderReview(submissionId: string, changedBy: string, notes?: string): Promise<{
        success: boolean;
        data: any;
    }>;
    raiseQuery(submissionId: string, queryType: string, queryDescription: string, raisedBy: string, dueDate?: Date, docsChecklist?: any[], attachments?: any[]): Promise<{
        success: boolean;
        data: any;
    }>;
    respondToQuery(queryId: string, response: string, respondedBy: string, attachments?: any[], docsChecklist?: any[]): Promise<{
        success: boolean;
        data: any;
    }>;
    sanctionApplication(submissionId: string, sanctionDetails: {
        sanctionAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        roiSubsidy?: number;
        tenure: number;
        decisionNotes?: string;
    }, decidedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    conditionalSanctionApplication(submissionId: string, sanctionDetails: {
        sanctionAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        tenure: number;
        conditions: (string | {
            text: string;
            deadline?: string;
        })[];
        decisionNotes?: string;
    }, decidedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    updateConditionStatus(submissionId: string, conditionIndex: number, status: 'PENDING' | 'MET' | 'WAIVED', updatedBy: string): Promise<{
        success: boolean;
        data: any;
        allConditionsMet: boolean;
    }>;
    acceptCounterOffer(submissionId: string, acceptedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    rejectCounterOffer(submissionId: string, reason: string, rejectedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    partialSanctionApplication(submissionId: string, details: {
        approvedAmount: number;
        requestedAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        tenure: number;
        decisionNotes?: string;
    }, decidedBy: string): Promise<{
        success: boolean;
        data: any;
        shortfallAmount: number;
    }>;
    makeCounterOffer(submissionId: string, counterOfferDetails: {
        sanctionAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        tenure: number;
        terms: string;
    }, decidedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    rejectApplication(submissionId: string, rejectionDetails: {
        reason: string;
        category: string;
        decisionNotes?: string;
    }, decidedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    moveToProcessingFee(submissionId: string, feeAmount: number, changedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    markFeeAsPaid(submissionId: string, changedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    confirmDisbursement(submissionId: string, disbursementDetails: {
        amount: number;
        referenceNo: string;
    }, confirmedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    allowResubmission(submissionId: string, authorizedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    private getSubmission;
    private isValidTransition;
    private recordWorkflowHistory;
    getSubmissionWithDetails(submissionId: string): Promise<{
        submission: any;
        queries: any[];
        history: any[];
    }>;
    getBankIncomingApplications(bankId: string, filters?: {
        status?: string;
        limit?: number;
        offset?: number;
    }): Promise<{
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
        };
    }>;
    getBankWorkflowAnalytics(bankId: string): Promise<{
        totalApplications: number;
        byStatus: Record<string, number>;
        byDecision: Record<string, number>;
        totalSanctioned: any;
        totalDisbursed: any;
        pendingDecision: number;
    }>;
    addQueryMessage(queryId: string, message: string, sender: string, attachments?: any[]): Promise<{
        success: boolean;
        data: any;
    }>;
    createQueryTemplate(data: {
        bankId: string;
        templateName: string;
        queryType: string;
        queryDescription: string;
        docsChecklist?: any[];
    }): Promise<{
        success: boolean;
        data: any;
    }>;
    getQueryTemplatesByBank(bankId: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    updateQueryTemplate(templateId: string, data: {
        templateName?: string;
        queryType?: string;
        queryDescription?: string;
        docsChecklist?: any[];
    }): Promise<{
        success: boolean;
        data: any;
    }>;
    deleteQueryTemplate(templateId: string): Promise<{
        success: boolean;
        message: string;
    }>;
    setSubmissionHold(submissionId: string, reason: string, changedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    resumeSubmissionHold(submissionId: string, changedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    bulkTransferSubmissions(submissionIds: string[], officerId: string, officerName: string, changedBy: string): Promise<{
        success: boolean;
        count: number;
        data: any[];
    }>;
    updateFeeStatus(submissionId: string, status: 'PAID' | 'WAIVED' | 'REFUNDED', paymentRef?: string, changedBy?: string): Promise<{
        success: boolean;
        data: any;
    }>;
    scheduleDisbursementTranche(submissionId: string, amount: number, dueDate: Date, remarks?: string): Promise<{
        success: boolean;
        data: any;
        scheduledTranche: {
            trancheNumber: number;
            amount: number;
            status: string;
            dueDate: string;
            remarks: string;
            createdAt: string;
        };
        remainingSanction: number;
    }>;
    confirmDisbursementTranche(submissionId: string, trancheNumber: number, referenceNo: string, confirmedBy: string): Promise<{
        success: boolean;
        data: any;
        confirmedTranche: any;
        remainingSanction: number;
    }>;
    getTranchesSummary(submissionId: string): Promise<{
        sanctionAmount: any;
        totalDisbursed: any;
        remainingAmount: number;
        nextTrancheDueDate: any;
        tranches: any[];
    }>;
    amendSanctionTerms(submissionId: string, newTerms: {
        sanctionAmount?: number;
        roiEffective?: number;
        tenure?: number;
    }, reason: string, effectiveDate: Date, amendedBy: string): Promise<{
        success: boolean;
        data: any;
        amendment: {
            id: any;
            originalTerms: {
                sanctionAmount: any;
                roiEffective: any;
                tenure: any;
            };
            newTerms: {
                sanctionAmount: any;
                roiEffective: any;
                tenure: any;
            };
            diff: any;
            reason: string;
            effectiveDate: string;
            amendedBy: string;
            amendedAt: string;
        };
    }>;
    requestCancellation(submissionId: string, reason: string, requestedBy: string): Promise<{
        success: boolean;
        data: any;
    }>;
    confirmCancellation(submissionId: string, confirmedBy: string): Promise<{
        success: boolean;
        data: any;
        refundPercent: number;
        refundAmount: number;
    }>;
    submitQualityRating(submissionId: string, ratings: {
        documentation: number;
        credit: number;
        profile: number;
        communication: number;
    }, comments: string, ratedBy: string): Promise<{
        success: boolean;
        data: any;
        rating: {
            documentation: number;
            credit: number;
            profile: number;
            communication: number;
            overallAverage: number;
            comments: string;
            ratedBy: string;
            ratedAt: string;
        };
    }>;
    getCrossBankHistory(submissionId: string): Promise<{
        studentId: any;
        currentSubmissionId: string;
        historyCount: number;
        history: {
            applicationNumber: any;
            id: any;
            applicationId: any;
            bankName: any;
            workflowStatus: any;
            submittedAt: any;
            decisionStatus: any;
            rejectionReason: any;
            rejectionCategory: any;
        }[];
    }>;
    grantStudentConsent(studentId: string, bankId: string, isGranted: boolean, ipAddress?: string, userAgent?: string): Promise<{
        success: boolean;
        data: any;
    }>;
    verifyStudentConsent(studentId: string, bankId: string): Promise<boolean>;
    getPipelineFunnelAnalytics(bankId?: string): Promise<{
        success: boolean;
        bankId: string;
        funnel: {
            SUBMITTED_TO_BANK: number;
            FILE_LOGGED: number;
            UNDER_REVIEW: number;
            QUERY_RAISED: number;
            SANCTIONED: number;
            DISBURSEMENT_PENDING: number;
            DISBURSED: number;
            CANCELLED_OR_REJECTED: number;
        };
    }>;
}
