import type { Response } from 'express';
import { BankWorkflowService } from './bank-workflow.service';
export declare class BankWorkflowController {
    private readonly workflowService;
    constructor(workflowService: BankWorkflowService);
    submitApplicationToBank(body: {
        applicationId: string;
        bankId: string;
        bankName: string;
        submittedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    logFile(submissionId: string, body: {
        lanNumber: string;
        loggedBy: string;
        notes?: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    moveToUnderReview(submissionId: string, body: {
        changedBy: string;
        notes?: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    raiseQuery(submissionId: string, body: {
        queryType: string;
        queryDescription: string;
        raisedBy: string;
        dueDate?: string;
        docsChecklist?: any[];
        attachments?: any[];
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    respondToQuery(queryId: string, body: {
        response: string;
        respondedBy: string;
        attachments?: any[];
        docsChecklist?: any[];
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    sanctionApplication(submissionId: string, body: {
        sanctionAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        roiSubsidy?: number;
        tenure: number;
        decisionNotes?: string;
        decidedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    conditionalSanctionApplication(submissionId: string, body: {
        sanctionAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        tenure: number;
        conditions: string[];
        decisionNotes?: string;
        decidedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    makeCounterOffer(submissionId: string, body: {
        sanctionAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        tenure: number;
        terms: string;
        decidedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    updateConditionStatus(submissionId: string, index: string, body: {
        status: 'PENDING' | 'MET' | 'WAIVED';
        updatedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    acceptCounterOffer(submissionId: string, body: {
        acceptedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    rejectCounterOffer(submissionId: string, body: {
        reason: string;
        rejectedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    partialSanctionApplication(submissionId: string, body: {
        approvedAmount: number;
        requestedAmount: number;
        roiType: string;
        roiBase: number;
        roiEffective: number;
        tenure: number;
        decisionNotes?: string;
        decidedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    rejectApplication(submissionId: string, body: {
        reason: string;
        category: string;
        decisionNotes?: string;
        decidedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    moveToProcessingFee(submissionId: string, body: {
        feeAmount: number;
        changedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    markFeeAsPaid(submissionId: string, body: {
        changedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    confirmDisbursement(submissionId: string, body: {
        amount: number;
        referenceNo: string;
        confirmedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    allowResubmission(submissionId: string, body: {
        authorizedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    getSubmissionDetails(submissionId: string, res: Response): Promise<Response<any, Record<string, any>>>;
    getBankIncomingApplications(bankId: string, res: Response, status?: string, limit?: string, offset?: string): Promise<Response<any, Record<string, any>>>;
    getBankWorkflowAnalytics(bankId: string, res: Response): Promise<Response<any, Record<string, any>>>;
    addQueryMessage(queryId: string, body: {
        message: string;
        sender: string;
        attachments?: any[];
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    createQueryTemplate(body: {
        bankId: string;
        templateName: string;
        queryType: string;
        queryDescription: string;
        docsChecklist?: any[];
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    getQueryTemplatesByBank(bankId: string, res: Response): Promise<Response<any, Record<string, any>>>;
    updateQueryTemplate(templateId: string, body: {
        templateName?: string;
        queryType?: string;
        queryDescription?: string;
        docsChecklist?: any[];
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    deleteQueryTemplate(templateId: string, res: Response): Promise<Response<any, Record<string, any>>>;
    setSubmissionHold(submissionId: string, body: {
        reason: string;
        changedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    resumeSubmissionHold(submissionId: string, body: {
        changedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    bulkTransferSubmissions(body: {
        submissionIds: string[];
        officerId: string;
        officerName: string;
        changedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    updateFeeStatus(submissionId: string, body: {
        status: 'PAID' | 'WAIVED' | 'REFUNDED';
        paymentRef?: string;
        changedBy?: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    scheduleDisbursementTranche(submissionId: string, body: {
        amount: number;
        dueDate: string;
        remarks?: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    confirmDisbursementTranche(submissionId: string, trancheNumber: string, body: {
        referenceNo: string;
        confirmedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    getTranchesSummary(submissionId: string, res: Response): Promise<Response<any, Record<string, any>>>;
    amendSanctionTerms(submissionId: string, body: {
        newTerms: {
            sanctionAmount?: number;
            roiEffective?: number;
            tenure?: number;
        };
        reason: string;
        effectiveDate: string;
        amendedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    requestCancellation(submissionId: string, body: {
        reason: string;
        requestedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    confirmCancellation(submissionId: string, body: {
        confirmedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    submitQualityRating(submissionId: string, body: {
        ratings: {
            documentation: number;
            credit: number;
            profile: number;
            communication: number;
        };
        comments: string;
        ratedBy: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    getCrossBankHistory(submissionId: string, res: Response): Promise<Response<any, Record<string, any>>>;
    grantStudentConsent(body: {
        studentId: string;
        bankId: string;
        isGranted: boolean;
        ipAddress?: string;
        userAgent?: string;
    }, res: Response): Promise<Response<any, Record<string, any>>>;
    verifyStudentConsent(studentId: string, bankId: string, res: Response): Promise<Response<any, Record<string, any>>>;
    getPipelineFunnelAnalytics(bankId: string, res: Response): Promise<Response<any, Record<string, any>>>;
}
