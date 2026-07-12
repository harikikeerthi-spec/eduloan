import { OpenRouterService } from './openrouter.service';
export interface UniversityData {
    name: string;
    rank: string;
    tuition: string;
    rate: string;
    salary: string;
    loc: string;
}
export declare class UniversityComparisonService {
    private readonly openRouter;
    constructor(openRouter: OpenRouterService);
    compare(uni1: string, uni2: string, program1?: string, program2?: string): Promise<{
        uni1: UniversityData;
        uni2: UniversityData;
    }>;
    compareShortlist(shortlist: Array<{
        name: string;
        course: string;
    }>, profile: {
        bachelors?: string;
        workExp?: string;
        gpa?: string;
    }): Promise<any>;
}
