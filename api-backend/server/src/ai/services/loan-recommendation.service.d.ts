import { OpenRouterService } from './openrouter.service';
export interface LoanOffer {
    id: string;
    bank: string;
    name: string;
    minScore: number;
    minCredit: number;
    minRatio: number;
    maxLoan: number;
    requiresCoApplicant: boolean;
    requiresCollateral: boolean;
    apr: string;
    coverage: string;
    bestFor: string;
}
export interface LoanRecommendationResult {
    primary: {
        offer: LoanOffer;
        fit: number;
    };
    alternatives: Array<{
        offer: LoanOffer;
        fit: number;
    }>;
}
export declare class LoanRecommendationService {
    private readonly openRouter;
    constructor(openRouter: OpenRouterService);
    recommendLoans(score: number, credit: number, ratio: number, loan: number, coApplicant: 'yes' | 'no', collateral: 'yes' | 'no', study: string): Promise<LoanRecommendationResult>;
    recommendChatLoans(profile: any): Promise<any>;
}
