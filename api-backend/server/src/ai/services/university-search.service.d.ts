import { OpenRouterService } from './openrouter.service';
export interface University {
    name: string;
    country: string;
    city?: string;
    ranking?: number;
    worldRanking?: number;
    type?: string;
    website?: string;
    description?: string;
    popularCourses?: string[];
    averageFees?: string;
    acceptanceRate?: number;
    scholarships?: boolean;
    logoUrl?: string;
    imageUrl?: string;
    isFeatured?: boolean;
}
export interface UniversityDetails extends University {
    admissionRequirements?: {
        minGPA?: string;
        testScores?: string[];
        languageRequirements?: string[];
    };
    programs?: Array<{
        name: string;
        description?: string;
        tuition?: string;
    }>;
    employmentStats?: {
        employmentRate?: number;
        averageSalary?: string;
        topEmployers?: string[];
    };
    facilities?: string[];
    funFacts?: string[];
    whyStudyHere?: string[];
    notableAlumni?: string[];
}
export declare class UniversitySearchService {
    private readonly openRouterService;
    constructor(openRouterService: OpenRouterService);
    searchUniversitiesByCountry(countries: string[], limit?: number): Promise<University[]>;
    getUniversityDetailsFull(universityName: string, country: string): Promise<UniversityDetails>;
    validateUniversityRealness(universities: University[]): Promise<University[]>;
    getPopularCountries(): Promise<string[]>;
}
