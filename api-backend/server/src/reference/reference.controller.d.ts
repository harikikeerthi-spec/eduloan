import { ReferenceService } from './reference.service';
export declare class ReferenceController {
    private referenceService;
    constructor(referenceService: ReferenceService);
    getAllLoanTypes(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getPopularLoanTypes(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getLoanTypeById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getAllUniversities(country?: string, ranking?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getFeaturedUniversities(limit?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getUniversityById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getUniversitiesByCountry(country: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getAllBanks(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getPopularBanks(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getBankById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getBanksByType(type: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getAllCountries(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getPopularCountries(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getCountryById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getCountryByCode(code: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getCountriesByRegion(region: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getAllScholarships(country?: string, type?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getScholarshipById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getScholarshipsByCountry(country: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getAllCourses(level?: string, field?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getPopularCourses(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getCourseById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getCoursesByLevel(level: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getCoursesByField(field: string): Promise<{
        success: boolean;
        data: any[];
    }>;
}
