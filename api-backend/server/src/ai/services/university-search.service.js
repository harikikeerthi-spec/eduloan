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
Object.defineProperty(exports, "__esModule", { value: true });
exports.UniversitySearchService = void 0;
const common_1 = require("@nestjs/common");
const openrouter_service_1 = require("./openrouter.service");
let UniversitySearchService = class UniversitySearchService {
    openRouterService;
    constructor(openRouterService) {
        this.openRouterService = openRouterService;
    }
    async searchUniversitiesByCountry(countries, limit = 10) {
        if (!countries || countries.length === 0) {
            throw new Error('At least one country must be provided');
        }
        const countriesStr = countries.join(', ');
        const prompt = `You are an expert in international education and university rankings. Your task is to list REAL, ACCREDITED universities in the following countries: ${countriesStr}

For each country, list approximately ${limit} top universities that actually exist and are well-known.

Return a JSON object with a "universities" key. The value should be an array with this structure:
{
  "universities": [
    {
      "name": "Full University Name",
      "loc": "City, Country",
      "country": "Country Name",
      "rank": 15,
      "worldRanking": 150,
      "type": "Public/Private",
      "website": "https://example.com",
      "description": "Brief description of the university",
      "courses": ["Engineering", "Business", "Medicine"],
      "tuition": 25000,
      "accept": 15,
      "min_gpa": 7.5,
      "min_ielts": 6.5,
      "min_toefl": 90,
      "scholarships": true,
      "loan": true
    }
  ]
}

CRITICAL RULES:
1. ONLY include REAL universities that actually exist.
2. Numeric fields MUST be single integers. DO NOT use ranges like "351-400". If a range is known, use the middle or lower bound as a single integer.
3. "rank" and "worldRanking" MUST be integers.
4. "accept" MUST be an integer (e.g. 15 for 15%).
5. "tuition" MUST be an integer in USD.
6. Return ONLY valid JSON.`;
        try {
            const response = await this.openRouterService.getJson(prompt);
            let universities = response.universities || (Array.isArray(response) ? response : []);
            const validUniversities = universities.filter(uni => uni && typeof uni === 'object' && uni.name && typeof uni.name === 'string').map(uni => {
                const toInt = (val) => {
                    if (typeof val === 'number')
                        return Math.floor(val);
                    if (typeof val === 'string') {
                        const cleaned = val.split('-')[0].replace(/[^\d]/g, '');
                        return parseInt(cleaned, 10) || 0;
                    }
                    return 0;
                };
                return {
                    ...uni,
                    rank: toInt(uni.rank || uni.worldRanking),
                    worldRanking: toInt(uni.worldRanking || uni.rank),
                    accept: toInt(uni.accept || uni.acceptanceRate),
                    tuition: toInt(uni.tuition),
                    min_gpa: parseFloat(String(uni.min_gpa || 7.0)),
                    slug: uni.slug || uni.name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
                    courses: Array.isArray(uni.courses) ? uni.courses : []
                };
            });
            return validUniversities;
        }
        catch (error) {
            console.error('University search failed:', error);
            throw new Error(`Failed to search universities: ${error.message}`);
        }
    }
    async getUniversityDetailsFull(universityName, country) {
        if (!universityName || !country) {
            throw new Error('University name and country are required');
        }
        const prompt = `You are an expert in international education. Provide comprehensive, accurate information about ${universityName} in ${country}.

Return detailed information as a JSON object with this structure:
{
  "name": "Full University Name",
  "country": "Country",
  "city": "City",
  "ranking": 15,
  "worldRanking": 150,
  "type": "Public/Private/Research",
  "website": "https://www.university-official-domain.edu",
  "description": "Detailed description",
  "popularCourses": ["Course1", "Course2", "Course3"],
  "averageFees": "Tuition range per year",
  "acceptanceRate": 15,
  "scholarships": true,
  "admissionRequirements": {
    "minGPA": "3.5 or equivalent",
    "testScores": ["GMAT", "GRE"],
    "languageRequirements": ["TOEFL 90+", "IELTS 6.5+"]
  },
  "programs": [
    { "name": "Program Name", "description": "Program details", "tuition": "Annual tuition" }
  ],
  "employmentStats": {
    "employmentRate": 95,
    "averageSalary": "Average graduate salary",
    "topEmployers": ["Company1", "Company2", "Company3"]
  },
  "facilities": ["Facility1", "Facility2"],
  "funFacts": ["Fact1", "Fact2"],
  "whyStudyHere": ["Reason1", "Reason2"],
  "notableAlumni": ["Alumni1", "Alumni2"]
}

CRITICAL: "website" MUST be the actual original official university domain (e.g. mit.edu, cam.ac.uk).
Return ONLY valid JSON.`;
        try {
            const details = await this.openRouterService.getJson(prompt);
            return details;
        }
        catch (error) {
            console.error('Failed to fetch university details:', error);
            throw new Error(`Failed to fetch details for ${universityName}: ${error.message}`);
        }
    }
    async validateUniversityRealness(universities) {
        if (!universities || universities.length === 0) {
            return [];
        }
        const universityNames = universities.map(u => `${u.name} (${u.country})`).join(', ');
        const prompt = `You are an expert in international education and university rankings.

Review the following list of universities and identify which ones are REAL, ACCREDITED institutions that actually exist:

${universityNames}

For each university, respond with ONLY a JSON array of objects with this structure:
[
  {
    "name": "University Name",
    "country": "Country",
    "isReal": true/false,
    "confidence": 0.95
  }
]

Return ONLY the JSON array with validation results. No other text.`;
        try {
            const validationResults = await this.openRouterService.getJson(prompt);
            const realUniversities = universities.filter(uni => {
                const validation = validationResults.find(v => v.name.toLowerCase() === uni.name.toLowerCase() &&
                    v.country.toLowerCase() === uni.country.toLowerCase());
                return validation ? validation.isReal && validation.confidence > 0.8 : true;
            });
            return realUniversities;
        }
        catch (error) {
            console.error('University validation failed:', error);
            return universities;
        }
    }
    async getPopularCountries() {
        const prompt = `List the top 15 most popular countries for international students seeking higher education. Return a JSON object with a "countries" key.
    
    Example format:
    { "countries": ["United States", "United Kingdom", "Canada", "Australia"] }
    
    MUST respond ONLY with JSON.`;
        try {
            const response = await this.openRouterService.getJson(prompt);
            const countries = response.countries || (Array.isArray(response) ? response : []);
            return Array.isArray(countries) ? countries : [];
        }
        catch (error) {
            console.error('Failed to fetch popular countries:', error);
            return [
                'United States',
                'United Kingdom',
                'Canada',
                'Australia',
                'Germany',
                'France',
                'Netherlands',
                'Switzerland',
                'Singapore',
                'Japan',
                'New Zealand',
                'Sweden',
                'Ireland',
                'Spain',
                'Italy',
            ];
        }
    }
};
exports.UniversitySearchService = UniversitySearchService;
exports.UniversitySearchService = UniversitySearchService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [openrouter_service_1.OpenRouterService])
], UniversitySearchService);
//# sourceMappingURL=university-search.service.js.map