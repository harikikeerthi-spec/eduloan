import { OpenRouterService } from './openrouter.service';
interface GradeConversionInput {
    inputType: 'letterGrade' | 'percentage' | 'gpa' | 'cgpa' | 'marks';
    inputValue: string | number;
    totalMarks?: number;
    outputType: 'letterGrade' | 'percentage' | 'gpa' | 'cgpa';
    gradingSystem?: 'US' | 'UK' | 'India' | 'Canada' | 'Australia';
}
interface GradeConversionResult {
    inputGrade: string;
    outputGrade: string;
    percentage: number;
    gpa: number;
    cgpa: number;
    letterGrade: string;
    classification: string;
    internationalEquivalent: {
        US: string;
        UK: string;
        India: string;
    };
    analysis: {
        strength: string;
        competitiveness: string;
        recommendations: string[];
    };
}
export declare class GradeConversionService {
    private readonly openRouter;
    constructor(openRouter: OpenRouterService);
    convertGrade(input: GradeConversionInput): Promise<GradeConversionResult>;
    comparePerformance(assessments: {
        name: string;
        percentage: number;
    }[]): Promise<any>;
}
export {};
