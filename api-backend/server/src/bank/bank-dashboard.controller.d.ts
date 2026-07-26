import { BankDashboardService } from './bank-dashboard.service';
import { SupabaseService } from '../supabase/supabase.service';
export declare class BankDashboardController {
    private readonly dashboardService;
    private readonly supabase;
    constructor(dashboardService: BankDashboardService, supabase: SupabaseService);
    getProducts(req: any): Promise<any[]>;
    addProduct(req: any, body: any): Promise<any>;
    updateProduct(productId: string, body: any): Promise<any>;
    getBranches(req: any): Promise<any[]>;
    addBranch(req: any, body: any): Promise<any>;
    createFile(req: any, body: any): Promise<any>;
    listFiles(req: any, status?: string, lanNumber?: string, queryBankId?: string): Promise<any[]>;
    getFile(fileId: string): Promise<any>;
    logFile(req: any, applicationId: string, body: any): Promise<any>;
    getFileLog(fileId: string): Promise<any>;
    getByLAN(lanNumber: string): Promise<any>;
    uploadDocuments(req: any, fileId: string, body: any): Promise<any>;
    getDocuments(fileId: string): Promise<any[]>;
    getDocument(fileId: string, documentId: string): Promise<any>;
    downloadDocuments(fileId: string): Promise<any>;
    getFileTimeline(applicationId: string): Promise<any[]>;
    getFileEvents(applicationId: string, type?: string): Promise<any[]>;
    validateLAN(body: any): Promise<any>;
    checkLAN(lanNumber: string): Promise<any>;
    getLANDetails(lanNumber: string): Promise<any>;
    setROI(req: any, applicationId: string, body: any): Promise<any>;
    setProcessingFee(req: any, applicationId: string, body: any): Promise<any>;
    updateProcessingFee(req: any, applicationId: string, body: any): Promise<any>;
    sanctionApplication(req: any, applicationId: string, body: any): Promise<any>;
    updateSanction(req: any, applicationId: string, body: any): Promise<any>;
    recordDecision(req: any, fileId: string, body: any): Promise<any>;
    getAllowedTransitions(req: any, applicationId: string): Promise<any>;
    transitionStatus(req: any, applicationId: string, body: {
        targetStatus: string;
        reason?: string;
    }): Promise<any>;
    recordBankDecision(req: any, applicationId: string, body: any): Promise<any>;
    raiseQuery(req: any, applicationId: string, body: any): Promise<any>;
    getQueries(req: any, applicationId?: string): Promise<any[]>;
    getQuery(queryId: string): Promise<any>;
    respondToQuery(req: any, queryId: string, body: any): Promise<any>;
    getQueryResponses(queryId: string): Promise<any[]>;
    resolveQuery(req: any, queryId: string, body: any): Promise<any>;
    recordConsent(req: any, applicationId: string, body: any): Promise<any>;
    getConsent(applicationId: string): Promise<any>;
    updateReferralFee(req: any, applicationId: string, body: any): Promise<any>;
    confirmDisbursement(req: any, applicationId: string, body: any): Promise<any>;
    getDisbursements(applicationId: string): Promise<any[]>;
    getAllDisbursements(req: any): Promise<any[]>;
    rateQuality(req: any, applicationId: string, body: any): Promise<any>;
    getChannelAnalytics(req: any): Promise<any>;
    getRejectionAnalytics(req: any): Promise<any>;
    getPipelineAnalytics(req: any): Promise<any>;
    getAgingAnalytics(req: any): Promise<any>;
    getSLAAnalytics(req: any): Promise<any>;
    getAuditLogs(applicationId: string): Promise<any[]>;
    addNote(req: any, fileId: string, body: {
        content: string;
        isPinned?: boolean;
    }): Promise<any>;
    getNotes(req: any, fileId: string): Promise<any[]>;
    updateNote(req: any, noteId: string, body: {
        content: string;
    }): Promise<any>;
    deleteNote(req: any, noteId: string): Promise<void>;
    getTagLibrary(): {
        tags: string[];
    };
    addTag(req: any, fileId: string, body: {
        tag: string;
    }): Promise<any>;
    removeTag(req: any, fileId: string, tag: string): Promise<void>;
    getFilesByTag(req: any, tag: string): Promise<any[]>;
    private resolveBankId;
    private resolveBankIdOrAll;
}
