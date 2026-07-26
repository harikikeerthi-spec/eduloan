import { AdminApplicationService } from './admin-application.service';
export declare class AdminApplicationController {
    private adminApplicationService;
    constructor(adminApplicationService: AdminApplicationService);
    addRemark(appId: string, body: {
        type: 'suggestion' | 'remark' | 'warning' | 'approval_note';
        content: string;
    }, req: any): Promise<{
        success: boolean;
        data: any;
    }>;
    getRemarks(appId: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    assignMentorCounselor(appId: string, body: {
        mentorId: string;
        mentorName: string;
        counselorId: string;
        counselorName: string;
    }, req: any): Promise<{
        success: boolean;
        data: any;
    }>;
    assessRisk(appId: string, body: {
        riskLevel: 'low' | 'medium' | 'high';
        creditScore?: number;
        notes?: string;
    }): Promise<{
        success: boolean;
        data: any;
    }>;
    batchProcessApplications(body: {
        applicationIds: string[];
        action: 'approve' | 'reject' | 'flag' | 'send_request';
        remarks: string;
    }, req: any): Promise<{
        success: boolean;
        processedCount: number;
        data: any[];
    }>;
    checkEligibility(appId: string): Promise<{
        success: boolean;
        data: {
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
        };
    }>;
    getPortfolioAnalysis(req: any): Promise<{
        success: boolean;
        data: {
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
        };
    }>;
    getComplianceReport(req: any): Promise<{
        success: boolean;
        data: {
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
        };
    }>;
}
