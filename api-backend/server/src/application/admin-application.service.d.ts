import { SupabaseService } from '../supabase/supabase.service';
interface ApplicationRemark {
    applicationId: string;
    type: 'suggestion' | 'remark' | 'warning' | 'approval_note';
    content: string;
    authorId: string;
    authorName: string;
    isInternal: boolean;
}
interface MentorAssignment {
    applicationId: string;
    mentorId: string;
    mentorName: string;
    counselorId: string;
    counselorName: string;
}
interface RiskAssessment {
    applicationId: string;
    riskLevel: 'low' | 'medium' | 'high';
    creditScore?: number;
    notes?: string;
}
export declare class AdminApplicationService {
    private db;
    constructor(db: SupabaseService);
    addRemark(appId: string, remark: ApplicationRemark): Promise<{
        success: boolean;
        data: any;
    }>;
    getApplicationRemarks(appId: string): Promise<any[]>;
    assignMentorCounselor(assignment: MentorAssignment): Promise<{
        success: boolean;
        data: any;
    }>;
    assessRisk(assessment: RiskAssessment): Promise<{
        success: boolean;
        data: any;
    }>;
    batchProcessApplications(applicationIds: string[], action: 'approve' | 'reject' | 'flag' | 'send_request', remarks: string, adminId: string, adminName: string): Promise<{
        success: boolean;
        processedCount: number;
        data: any[];
    }>;
    checkEligibility(appId: string): Promise<{
        overallStatus: string;
        passCount: number;
        failCount: number;
        assessments: {
            ageCheck: {
                criteria: string;
                status: string;
            };
            admissionValidation: {
                criteria: string;
                status: string;
            };
            incomeCheck: {
                criteria: string;
                status: string;
            };
            creditScore: {
                criteria: string;
                status: string;
            };
            noDefaults: {
                criteria: string;
                status: string;
            };
            courseDuration: {
                criteria: string;
                status: string;
            };
            institutionAccreditation: {
                criteria: string;
                status: string;
            };
        };
        recommendation: string;
    }>;
    getPortfolioAnalysis(user?: any, bankId?: string): Promise<{
        totalPortfolioValue: any;
        totalApplications: number;
        approvalRate: number;
        defaultRate: number;
        avgLoanSize: number;
        disbursedAmount: any;
        topUniversities: {
            name: string;
            count: number;
            approvalRate: number;
        }[];
        disbursementTrend: {
            month: string;
            amount: number;
        }[];
    }>;
    getComplianceReport(user?: any, bankId?: string): Promise<{
        rbiCompliance: {
            regulation: string;
            status: string;
            detail: string;
        };
        nhbCompliance: {
            regulation: string;
            status: string;
            detail: string;
        };
        dataProtection: {
            regulation: string;
            status: string;
            detail: string;
        };
        gstCompliance: {
            regulation: string;
            status: string;
            detail: string;
        };
        kycAml: {
            regulation: string;
            status: string;
            detail: string;
        };
        overallCompliance: number;
    }>;
    private checkAge;
    private calculateMaxLoan;
    private updateApplicationRemarkCount;
    private createAuditLog;
}
export {};
