import { EligibilityService } from './services/eligibility.service';
import { LoanRecommendationService } from './services/loan-recommendation.service';
import { SopAnalysisService } from './services/sop-analysis.service';
import { GradeConversionService } from './services/grade-conversion.service';
import { UniversityComparisonService } from './services/university-comparison.service';
import { AdmitPredictorService } from './services/admit-predictor.service';
import { OpenRouterService } from './services/openrouter.service';
import { UniversitySearchService, UniversityDetails } from './services/university-search.service';
import { VisaInterviewService, InterviewMessage, EvaluationResult } from './services/visa-interview.service';
import { SupabaseService } from '../supabase/supabase.service';
export declare class AiController {
    private readonly eligibilityService;
    private readonly loanRecommendationService;
    private readonly sopAnalysisService;
    private readonly gradeConversionService;
    private readonly universityComparisonService;
    private readonly admitPredictorService;
    private readonly openRouterService;
    private readonly universitySearchService;
    private readonly visaInterviewService;
    private readonly supabase;
    constructor(eligibilityService: EligibilityService, loanRecommendationService: LoanRecommendationService, sopAnalysisService: SopAnalysisService, gradeConversionService: GradeConversionService, universityComparisonService: UniversityComparisonService, admitPredictorService: AdmitPredictorService, openRouterService: OpenRouterService, universitySearchService: UniversitySearchService, visaInterviewService: VisaInterviewService, supabase: SupabaseService);
    checkEligibility(data: any): Promise<{
        success: boolean;
        eligibility: import("./services/eligibility.service").EligibilityResult;
        recommendations: import("./services/loan-recommendation.service").LoanRecommendationResult;
    }>;
    getLoanRecommendations(data: any): Promise<{
        primary: {
            offer: any;
            fit: number;
        };
        alternatives: {
            offer: any;
            fit: number;
        }[];
    }>;
    analyzeSop(data: {
        text?: string;
        sop?: string;
    }): Promise<{
        success: boolean;
        analysis: import("./services/sop-analysis.service").SopAnalysisResult;
    }>;
    humanizeSop(data: {
        text: string;
    }): Promise<{
        humanizedText: string;
        improvements: string[];
        success: boolean;
    }>;
    convertGrades(data: {
        inputType: 'letterGrade' | 'percentage' | 'gpa' | 'cgpa' | 'marks';
        inputValue: string | number;
        totalMarks?: number;
        outputType: 'letterGrade' | 'percentage' | 'gpa' | 'cgpa';
        gradingSystem?: 'US' | 'UK' | 'India' | 'Canada' | 'Australia';
    }): Promise<any>;
    analyzeGrades(data: {
        marks?: number[];
        subjects?: string[];
        totalMarks?: number;
        gpa?: number;
        percentage?: number;
    }): Promise<any>;
    compareGrades(data: {
        assessments: Array<{
            name: string;
            percentage: number;
        }>;
    }): Promise<any>;
    compareUniversities(data: {
        uni1: string;
        uni2: string;
        program1?: string;
        program2?: string;
    }): Promise<{
        success: boolean;
        data: {
            uni1: import("./services/university-comparison.service").UniversityData;
            uni2: import("./services/university-comparison.service").UniversityData;
        };
    }>;
    compareShortlist(data: {
        shortlist: Array<{
            name: string;
            course: string;
        }>;
        profile: {
            bachelors?: string;
            workExp?: string;
            gpa?: string;
        };
    }): Promise<{
        success: boolean;
        data: any;
    }>;
    predictAdmission(body: any): Promise<{
        success: boolean;
        prediction: unknown;
    }>;
    checkRelevance(data: {
        topic?: string;
        title?: string;
        content: string;
    }): Promise<{
        success: boolean;
        relevant: boolean;
        isRelevant: boolean;
        reason: string | undefined;
    }>;
    search(data: any): Promise<{
        success: boolean;
        universities: any[];
        results?: undefined;
        message?: undefined;
    } | {
        success: boolean;
        results: any[];
        universities?: undefined;
        message?: undefined;
    } | {
        success: boolean;
        message: string;
        results: never[];
        universities: never[];
    }>;
    searchAdvice(data: {
        query: string;
        type: 'university' | 'course' | 'ug_university';
        context?: any;
    }): Promise<{
        success: boolean;
        results: any[];
        message?: undefined;
    } | {
        success: boolean;
        message: string;
        results: never[];
    }>;
    suggestTags(data: {
        title: string;
    }): Promise<{
        success: boolean;
        tags: string[];
    }>;
    searchUniversities(data: any): Promise<{
        success: boolean;
        universities: any[];
        totalCount: number;
        source: string;
        message?: string;
    }>;
    searchCourses(data: {
        university?: string;
        query: string;
        degree?: string;
    }): Promise<{
        success: boolean;
        courses: any[];
    }>;
    getUniversityDetails(name: string, country: string): Promise<{
        success: boolean;
        details?: UniversityDetails | null;
        message?: string;
    }>;
    getPopularCountries(): Promise<{
        success: boolean;
        countries: string[];
        message?: undefined;
    } | {
        success: boolean;
        message: string;
        countries: never[];
    }>;
    startVisaInterview(data: {
        userProfile: Record<string, any>;
        visaType?: string;
        agentType?: string;
    }): Promise<{
        success: boolean;
        question: any;
        currentSection: any;
        completedSections: any;
        isInterviewOver: any;
        sections: import("./services/visa-interview.service").InterviewSection[];
        message?: undefined;
    } | {
        success: boolean;
        message: any;
        question?: undefined;
        currentSection?: undefined;
        completedSections?: undefined;
        isInterviewOver?: undefined;
        sections?: undefined;
    }>;
    continueVisaInterview(data: {
        userProfile: Record<string, any>;
        visaType?: string;
        agentType?: string;
        previousQuestion: string;
        transcript: string;
        currentSection: string;
        conversationHistory?: InterviewMessage[];
    }): Promise<{
        success: boolean;
        question: any;
        currentSection: any;
        completedSections: any;
        isInterviewOver: any;
        message?: undefined;
    } | {
        success: boolean;
        message: any;
        question?: undefined;
        currentSection?: undefined;
        completedSections?: undefined;
        isInterviewOver?: undefined;
    }>;
    evaluateVisaAnswer(data: {
        visaType?: string;
        question: string;
        transcript: string;
    }): Promise<{
        success: boolean;
        evaluation: EvaluationResult;
        message?: undefined;
    } | {
        success: boolean;
        message: any;
        evaluation?: undefined;
    }>;
    getVisaFinalReport(data: {
        visaType?: string;
        conversationHistory: InterviewMessage[];
        evaluations: EvaluationResult[];
    }): Promise<{
        success: boolean;
        report: any;
        message?: undefined;
    } | {
        success: boolean;
        message: any;
        report?: undefined;
    }>;
    saveVisaReport(data: {
        userId?: string;
        visaType: string;
        agentType?: string;
        userProfile?: any;
        overallScore: number;
        overallRisk: string;
        approvalLikelihood: string;
        sectionScores: any;
        strengths: string[];
        weaknesses: string[];
        criticalIssues: string[];
        ds160Inconsistencies: string[];
        tips: string[];
        verdict: string;
        messages: any;
        evaluations: any;
    }): Promise<{
        success: boolean;
        result: any;
        message?: undefined;
    } | {
        success: boolean;
        message: string;
        result?: undefined;
    }>;
    shortlist(data: {
        profile: any;
        userId?: string;
        messages?: any[];
    }): Promise<{
        success: boolean;
        recommendations: any[];
    }>;
    getShortlistChat(userId: string): Promise<{
        success: boolean;
        chat: any;
        message?: undefined;
    } | {
        success: boolean;
        message: string;
        chat?: undefined;
    }>;
}
