"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var ShortlistingService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ShortlistingService = void 0;
const common_1 = require("@nestjs/common");
const open_router_service_1 = require("./open-router.service");
const prisma_service_1 = require("../../prisma/prisma.service");
let ShortlistingService = ShortlistingService_1 = class ShortlistingService {
    openRouterService;
    prisma;
    logger = new common_1.Logger(ShortlistingService_1.name);
    constructor(openRouterService, prisma) {
        this.openRouterService = openRouterService;
        this.prisma = prisma;
    }
    popularCountries = [
        { name: 'USA', flag: '🇺🇸' },
        { name: 'UK', flag: '🇬🇧' },
        { name: 'Canada', flag: '🇨🇦' },
        { name: 'Australia', flag: '🇦🇺' },
        { name: 'Germany', flag: '🇩🇪' },
        { name: 'Ireland', flag: '🇮🇪' },
        { name: 'France', flag: '🇫🇷' },
        { name: 'Netherlands', flag: '🇳🇱' },
        { name: 'New Zealand', flag: '🇳🇿' },
        { name: 'Singapore', flag: '🇸🇬' },
        { name: 'Dubai (UAE)', flag: '🇦🇪' },
        { name: 'Italy', flag: '🇮🇹' },
        { name: 'Sweden', flag: '🇸🇪' },
        { name: 'Switzerland', flag: '🇨🇭' },
        { name: 'Spain', flag: '🇪🇸' },
    ];
    async searchCountries(query) {
        if (!query)
            return this.popularCountries;
        return this.popularCountries.filter((c) => c.name.toLowerCase().includes(query.toLowerCase()));
    }
    async searchFields(query) {
        const fields = [
            'Computer Science',
            'Data Science',
            'Business Analytics',
            'MBA',
            'Mechanical Engineering',
            'Electrical Engineering',
            'Civil Engineering',
            'Biotechnology',
            'Public Health',
            'Cybersecurity',
            'Artificial Intelligence',
            'Finance',
            'Marketing',
            'Architecture',
            'Psychology',
        ];
        if (!query)
            return fields;
        return fields.filter((f) => f.toLowerCase().includes(query.toLowerCase()));
    }
    async searchUniversities(query, degree, country) {
        try {
            const systemPrompt = `List 10 real universities/colleges matching '${query}' for ${degree} in ${country || 'any'}.
      Include exact matches for specific names (e.g. 'Vishnu College').
      For Indian results, include town (e.g. Bhimavaram).
      JSON array: [{"name": "Name", "country": "Country", "location": "City, State"}]`;
            const response = await this.openRouterService.generateResponse(systemPrompt, `Search: ${query}`);
            const jsonMatch = response.match(/\[[\s\S]*\]/);
            return JSON.parse(jsonMatch ? jsonMatch[0] : response);
        }
        catch (error) {
            this.logger.error('University search failed', error);
            return [];
        }
    }
    async searchCourses(university, query, degree) {
        try {
            const systemPrompt = `Return a list of 10 real courses/programs matching '${query}' at ${university} for ${degree} degree.
      Return ONLY a JSON array of strings or objects: ["Program Name"]`;
            const response = await this.openRouterService.generateResponse(systemPrompt, `Search: ${query}`);
            const jsonMatch = response.match(/\[[\s\S]*\]/);
            return JSON.parse(jsonMatch ? jsonMatch[0] : response);
        }
        catch (error) {
            this.logger.error('Course search failed', error);
            return [];
        }
    }
    async shortlist(profile, messages = []) {
        try {
            const systemPrompt = `You are a Study Abroad Consultant. Shortlist 5-6 universities.
      CRITICAL: Keep "reason" and "description" fields concise (1-2 sentences maximum) to avoid token truncation.
      JSON format:
      {
        "recommendations": [
          {
            "name": "Name", "chance": "High/Med/Low", "type": "Safe/Target/Ambitious", "rank": "Rank", "tuition": "USD", "location": "City, State",
            "country": "Country", "avgSalary": "Salary", "deadline": "Date", "reason": "Why", "programName": "Program", "logoUrl": "",
            "description": "Bio", "acceptanceRate": "%", "duration": "Years", "roi": "H/M/L", "theRank": "THE Rank", "costOfLiving": "USD", "websiteUrl": "url"
          }
        ]
      }`;
            const userPrompt = `Profile: ${JSON.stringify(profile)}
      Conversation History: ${JSON.stringify(messages)}`;
            const response = await this.openRouterService.generateResponse(systemPrompt, userPrompt, 0.7, 4096);
            const jsonMatch = response.match(/\{[\s\S]*\}/);
            const jsonStr = jsonMatch ? jsonMatch[0] : response;
            try {
                return JSON.parse(jsonStr);
            }
            catch (parseError) {
                this.logger.error('Failed to parse JSON. Raw JSON string tried to parse:', jsonStr);
                throw parseError;
            }
        }
        catch (error) {
            this.logger.error('Shortlisting failed', error);
            throw error;
        }
    }
    async saveShortlistChat(userId, messages, recommendations) {
        try {
            return await this.prisma.universityShortlistChat.upsert({
                where: { userId },
                update: {
                    messages: messages || [],
                    recommendations: recommendations || [],
                    updatedAt: new Date(),
                },
                create: {
                    userId,
                    messages: messages || [],
                    recommendations: recommendations || [],
                },
            });
        }
        catch (error) {
            this.logger.error(`Failed to save shortlist chat for user ${userId}`, error);
            throw error;
        }
    }
    async getLatestShortlistChat(userId) {
        try {
            return await this.prisma.universityShortlistChat.findUnique({
                where: { userId },
            });
        }
        catch (error) {
            this.logger.error(`Failed to get shortlist chat for user ${userId}`, error);
            throw error;
        }
    }
};
exports.ShortlistingService = ShortlistingService;
exports.ShortlistingService = ShortlistingService = ShortlistingService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [open_router_service_1.OpenRouterService,
        prisma_service_1.PrismaService])
], ShortlistingService);
//# sourceMappingURL=shortlisting.service.js.map