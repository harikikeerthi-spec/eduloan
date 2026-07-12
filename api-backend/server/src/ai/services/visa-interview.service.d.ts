import { OpenRouterService } from './openrouter.service';
export interface InterviewMessage {
    role: 'officer' | 'applicant';
    content: string;
    timestamp?: string;
}
export interface EvaluationResult {
    clarity: number;
    confidence: number;
    relevance: number;
    specificity: number;
    consistency: number;
    conciseness: number;
    persuasiveness: number;
    risk: 'Low' | 'Medium' | 'High';
    redFlags: string[];
    missingDetails: string[];
    suggestedImprovement: string[];
    overallScore: number;
    quickTip: string;
}
export interface InterviewSection {
    id: string;
    label: string;
    completed: boolean;
}
export declare class VisaInterviewService {
    private readonly openRouterService;
    constructor(openRouterService: OpenRouterService);
    getSections(): InterviewSection[];
    private getSystemPromptTemplate;
    private buildPrompt;
    startInterview(userProfile: Record<string, any>, visaType: string, agentType: string): Promise<any>;
    continueInterview(userProfile: Record<string, any>, visaType: string, previousQuestion: string, transcript: string, currentSection: string, conversationHistory: InterviewMessage[], agentType?: string): Promise<any>;
    evaluateAnswer(visaType: string, question: string, transcript: string): Promise<EvaluationResult>;
    generateFinalReport(visaType: string, conversationHistory: InterviewMessage[], evaluations: EvaluationResult[], interviewStopped?: boolean): Promise<any>;
}
