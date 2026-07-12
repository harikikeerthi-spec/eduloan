import { OpenRouterService } from './open-router.service';
import { PrismaService } from '../../prisma/prisma.service';
export declare class ShortlistingService {
    private readonly openRouterService;
    private readonly prisma;
    private readonly logger;
    constructor(openRouterService: OpenRouterService, prisma: PrismaService);
    private readonly popularCountries;
    searchCountries(query: string): Promise<any[]>;
    searchFields(query: string): Promise<string[]>;
    searchUniversities(query: string, degree: string, country?: string): Promise<any[]>;
    searchCourses(university: string, query: string, degree: string): Promise<any[]>;
    shortlist(profile: any, messages?: any[]): Promise<any>;
    saveShortlistChat(userId: string, messages: any[], recommendations: any[]): Promise<any>;
    getLatestShortlistChat(userId: string): Promise<any>;
}
