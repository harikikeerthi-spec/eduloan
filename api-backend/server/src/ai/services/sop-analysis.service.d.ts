import { OpenRouterService } from './openrouter.service';
export interface SopAnalysisCategory {
    name: string;
    score: number;
    weight: number;
}
export interface SopFeedback {
    issue: string;
    recommendation: string;
}
export interface SopAnalysisResult {
    totalScore: number;
    quality: 'excellent' | 'good' | 'fair' | 'needs-work';
    humanizeScore: number;
    plagiarismScore: number;
    categories: SopAnalysisCategory[];
    weakAreas: SopFeedback[];
    summary: string;
    humanizeFeedback: string;
    plagiarismFeedback: string;
}
export declare class SopAnalysisService {
    private readonly openRouter;
    constructor(openRouter: OpenRouterService);
    analyzeSop(text: string): Promise<SopAnalysisResult>;
    humanizeSop(text: string): Promise<{
        humanizedText: string;
        improvements: string[];
    }>;
}
