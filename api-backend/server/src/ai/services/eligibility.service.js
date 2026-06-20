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
exports.EligibilityService = void 0;
const common_1 = require("@nestjs/common");
const openrouter_service_1 = require("./openrouter.service");
const supabase_service_1 = require("../../supabase/supabase.service");
let EligibilityService = class EligibilityService {
    openRouter;
    supabase;
    constructor(openRouter, supabase) {
        this.openRouter = openRouter;
        this.supabase = supabase;
    }
    async calculateEligibilityScore(data) {
        const prompt = `
    Evaluate the loan eligibility for the following applicant:
    - Age: ${data.age}
    - Credit Score: ${data.credit}
    - Annual Income: ${data.income} (in INR)
    - Loan Amount Requested: ${data.loan} (in INR)
    - Employment: ${data.employment}
    - Study Level: ${data.study}
    - Co-Applicant: ${data.coApplicant}
    - Collateral: ${data.collateral}

    Perform a strict risk assessment.
    1. Calculate a risk score (0-100), where 100 is perfectly safe and 0 is high risk.
    2. Determine status (eligible, borderline, unlikely).
    3. Calculate Income-to-Loan Ratio.
    4. Estimate Rate Range and Coverage based on risk.
    5. Provide a professional summary explaining the decision.
    6. Provide 3 actionable recommendations to improve eligibility (e.g. "Increase credit score", "Add co-applicant").

    Return JSON format:
    {
      "score": number,
      "status": "eligible" | "borderline" | "unlikely",
      "ratio": number,
      "rateRange": "string",
      "coverage": "string",
      "summary": "string",
      "recommendations": ["string"]
    }

    Note: Credit score < 600 is generally risky. High loan vs low income is risky.
    `;
        try {
            return await this.openRouter.getJson(prompt);
        }
        catch (error) {
            console.error('Eligibility check failed', error);
            return {
                score: 50,
                status: 'borderline',
                ratio: 0,
                rateRange: '10-15%',
                coverage: 'Unknown',
                summary: 'AI Service Unavailable. Please try again later.',
                recommendations: ['Check internet connection', 'Try again later'],
            };
        }
    }
    async saveLog(data) {
        try {
            await this.supabase.getClient().from('LoanEligibilityCheck').insert({
                age: data.age,
                credit: data.credit,
                income: data.income,
                loan: data.loan,
                employment: data.employment,
                study: data.study,
                coApplicant: data.coApplicant,
                collateral: data.collateral,
                score: data.score,
                status: data.status,
                rateRange: data.rateRange,
                coverage: data.coverage,
                recommendations: data.recommendations,
                userId: data.userId || null,
            });
        }
        catch (e) {
            console.error('Failed to save eligibility log:', e);
        }
    }
};
exports.EligibilityService = EligibilityService;
exports.EligibilityService = EligibilityService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [openrouter_service_1.OpenRouterService,
        supabase_service_1.SupabaseService])
], EligibilityService);
//# sourceMappingURL=eligibility.service.js.map