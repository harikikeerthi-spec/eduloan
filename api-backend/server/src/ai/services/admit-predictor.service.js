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
exports.AdmitPredictorService = void 0;
const common_1 = require("@nestjs/common");
const openrouter_service_1 = require("./openrouter.service");
let AdmitPredictorService = class AdmitPredictorService {
    openRouter;
    constructor(openRouter) {
        this.openRouter = openRouter;
    }
    universities = [
        { name: 'Stanford University', tier: 1, minGpa: 3.8, avgGre: 328, avgSat: 1520, minIelts: 7.5, minToefl: 100, acceptanceRate: 4 },
        { name: 'Massachusetts Institute of Technology (MIT)', tier: 1, minGpa: 3.9, avgGre: 330, avgSat: 1540, minIelts: 7.5, minToefl: 100, acceptanceRate: 4 },
        { name: 'Harvard University', tier: 1, minGpa: 3.9, avgGre: 326, avgSat: 1530, minIelts: 7.5, minToefl: 100, acceptanceRate: 3 },
        { name: 'University of Oxford', tier: 1, minGpa: 3.7, avgGre: 320, minIelts: 7.5, acceptanceRate: 17 },
        { name: 'University of Cambridge', tier: 1, minGpa: 3.8, minIelts: 7.5, acceptanceRate: 21 },
        { name: 'Imperial College London', tier: 1, minGpa: 3.6, minIelts: 7.0, acceptanceRate: 14 },
        { name: 'University of Toronto', tier: 2, minGpa: 3.5, minIelts: 6.5, acceptanceRate: 43 },
        { name: 'University of British Columbia', tier: 2, minGpa: 3.3, minIelts: 6.5, acceptanceRate: 52 },
        { name: 'National University of Singapore (NUS)', tier: 1, minGpa: 3.7, minIelts: 6.5, acceptanceRate: 5 },
        { name: 'University of Melbourne', tier: 2, minGpa: 3.2, minIelts: 6.5, acceptanceRate: 70 },
        { name: 'Arizona State University', tier: 3, minGpa: 3.0, avgGre: 300, minIelts: 6.0, acceptanceRate: 88 },
        { name: 'Northeastern University', tier: 2, minGpa: 3.5, avgGre: 310, minIelts: 7.0, acceptanceRate: 18 },
        { name: 'University of Texas at Dallas', tier: 2, minGpa: 3.2, avgGre: 310, minIelts: 6.5, acceptanceRate: 79 },
    ];
    async predict(profile) {
        const prompt = `
        Predict the admission probability for a student applying to ${profile.targetUniversity}.
        
        Student Profile:
        - Program Level: ${profile.programLevel}
        - GPA: ${profile.gpa} (Scale: ${profile.gpaScale})
        - Test Score: ${profile.testScoreType} ${profile.testScore}
        - English Efficiency: ${profile.englishTestType} ${profile.englishTestScore}
        - Experience: ${profile.experienceYears} years
        - Research Papers: ${profile.researchPapers}
        
        Provide the result in JSON format:
        {
          "university": "${profile.targetUniversity}",
          "probability": number (0-100),
          "feedback": ["string", "string"],
          "tier": number (1, 2, or 3 based on university reputation)
        }

        Be realistic. Top universities (Ivy League, etc.) should have lower probabilities unless the profile is exceptional.
        `;
        try {
            return await this.openRouter.getJson(prompt);
        }
        catch (error) {
            console.error('Admit Predictor failed', error);
            return {
                university: profile.targetUniversity,
                probability: 50,
                feedback: ['AI service unavailable. Using default prediction.', 'Please check connection.'],
                tier: 2
            };
        }
    }
    getUniversitiesList() {
        return this.universities.map(u => u.name);
    }
};
exports.AdmitPredictorService = AdmitPredictorService;
exports.AdmitPredictorService = AdmitPredictorService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [openrouter_service_1.OpenRouterService])
], AdmitPredictorService);
//# sourceMappingURL=admit-predictor.service.js.map