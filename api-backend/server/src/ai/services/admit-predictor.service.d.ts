import { OpenRouterService } from './openrouter.service';
export interface StudentProfile {
    targetUniversity: string;
    gpa: number;
    gpaScale: 4 | 10;
    testScoreType: 'GRE' | 'GMAT' | 'SAT' | 'ACT' | 'None';
    testScore: number;
    englishTestType: 'IELTS' | 'TOEFL' | 'PTE' | 'None';
    englishTestScore: number;
    experienceYears: number;
    researchPapers: number;
    programLevel: 'Undergraduate' | 'Masters' | 'PhD' | 'MBA';
}
export declare class AdmitPredictorService {
    private readonly openRouter;
    constructor(openRouter: OpenRouterService);
    private universities;
    predict(profile: StudentProfile): Promise<unknown>;
    getUniversitiesList(): string[];
}
