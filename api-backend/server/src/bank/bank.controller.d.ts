import type { Response } from 'express';
import { BankService } from './bank.service';
export declare class BankController {
    private readonly bankService;
    constructor(bankService: BankService);
    private resolveBankName;
    getIncomingFiles(req: any, limit?: string, offset?: string): Promise<any[]>;
    logFile(req: any, id: string, lanNumber: string): Promise<any>;
    getDocuments(applicationId: string): Promise<any[]>;
    downloadDocumentsZip(applicationId: string, res: Response): Promise<void>;
    submitDecision(req: any, applicationId: string, decisionType: string, details: any): Promise<any>;
    raiseQuery(req: any, applicationId: string, content: string): Promise<any>;
    confirmDisbursement(req: any, applicationId: string, disbursementAmount: number, trancheNumber: number, transferMode: string, utrNumber: string): Promise<any>;
    conditionalSanction(req: any, applicationId: string, conditions: string[], deadline: string): Promise<any>;
    partialSanction(req: any, applicationId: string, sanctionAmount: number, shortfallAmount: number, reason: string): Promise<any>;
    counterOffer(req: any, applicationId: string, offeredAmount: number, offeredRate: number, offeredTenure: number): Promise<any>;
    fileQualityScore(applicationId: string, rating: number, feedback: string): Promise<any>;
    getChannelAnalytics(req: any): Promise<{
        success: boolean;
        bank: string;
        roiSpreads: {
            product: string;
            rate: number;
            type: string;
        }[];
        rejectionsByCause: {
            cause: string;
            count: number;
        }[];
    }>;
    getRejectionAnalytics(req: any): Promise<{
        success: boolean;
        bank: string;
        totalRejections: number;
        causes: {
            label: string;
            count: number;
        }[];
    }>;
    getSlaTracker(req: any): Promise<any>;
    getLoanProducts(req: any): Promise<any[]>;
    createLoanProduct(body: any): Promise<any>;
    updateLoanProduct(id: string, body: any): Promise<any>;
    getBranches(req: any): Promise<any[]>;
    createBranch(body: any): Promise<any>;
    getOfficers(req: any): Promise<any[]>;
    getFileDetail(id: string): Promise<any>;
    lookupByLan(lan: string): Promise<any>;
    getMyFiles(req: any, filters: any): Promise<any[]>;
    amendDecision(decisionId: string, applicationId: string, details: any, req: any): Promise<any>;
    uploadSanctionLetter(id: string, fileUrl: string, req: any): Promise<any>;
    setRoi(id: string, roiData: any, req: any): Promise<any>;
    setProcessingFee(id: string, feeData: any): Promise<any>;
    updateProcessingFee(id: string, updateData: any): Promise<any>;
    getQueryThread(queryId: string): Promise<any>;
    resolveQuery(queryId: string): Promise<any>;
    getAnalyticsMetrics(req: any): Promise<any>;
    exportApplicationsCsv(req: any): Promise<any>;
    exportMisReports(req: any): Promise<any>;
}
