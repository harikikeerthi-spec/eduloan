import { OpenRouterService } from './openrouter.service';
export interface ApplicationReviewResult {
    overallScore: number;
    recommendation: 'approve' | 'reject' | 'needs_review';
    completenessCheck: {
        score: number;
        missingFields: string[];
        filledFields: string[];
        percentage: number;
    };
    creditAssessment: {
        riskLevel: 'low' | 'medium' | 'high';
        incomeToLoanRatio: number;
        observations: string[];
    };
    documentCheck: {
        totalRequired: number;
        uploaded: number;
        verified: number;
        pending: number;
        status: 'complete' | 'partial' | 'missing';
    };
    eligibilityFlags: {
        flag: string;
        status: 'pass' | 'warning' | 'fail';
        detail: string;
    }[];
    aiSummary: string;
    aiRecommendations: string[];
    mentorReviewRequired: boolean;
    mentorReviewReasons: string[];
}
export declare class ApplicationReviewService {
    private readonly openRouter;
    constructor(openRouter: OpenRouterService);
    reviewApplication(application: any, documents: any[]): Promise<ApplicationReviewResult>;
    private checkCompleteness;
    private checkDocuments;
    private basicCreditAssessment;
    private performAIAnalysis;
    private determineMentorReview;
}
