"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiModule = void 0;
const common_1 = require("@nestjs/common");
const ai_controller_1 = require("./ai.controller");
const eligibility_service_1 = require("./services/eligibility.service");
const loan_recommendation_service_1 = require("./services/loan-recommendation.service");
const sop_analysis_service_1 = require("./services/sop-analysis.service");
const grade_conversion_service_1 = require("./services/grade-conversion.service");
const university_comparison_service_1 = require("./services/university-comparison.service");
const admit_predictor_service_1 = require("./services/admit-predictor.service");
const document_verification_service_1 = require("./services/document-verification.service");
const application_review_service_1 = require("./services/application-review.service");
const openrouter_service_1 = require("./services/openrouter.service");
const university_search_service_1 = require("./services/university-search.service");
const visa_interview_service_1 = require("./services/visa-interview.service");
const kyc_service_1 = require("./services/kyc.service");
let AiModule = class AiModule {
};
exports.AiModule = AiModule;
exports.AiModule = AiModule = __decorate([
    (0, common_1.Module)({
        imports: [],
        controllers: [ai_controller_1.AiController],
        providers: [
            openrouter_service_1.OpenRouterService,
            eligibility_service_1.EligibilityService,
            loan_recommendation_service_1.LoanRecommendationService,
            sop_analysis_service_1.SopAnalysisService,
            grade_conversion_service_1.GradeConversionService,
            university_comparison_service_1.UniversityComparisonService,
            admit_predictor_service_1.AdmitPredictorService,
            document_verification_service_1.DocumentVerificationService,
            application_review_service_1.ApplicationReviewService,
            university_search_service_1.UniversitySearchService,
            visa_interview_service_1.VisaInterviewService,
            kyc_service_1.KycService,
        ],
        exports: [
            openrouter_service_1.OpenRouterService,
            eligibility_service_1.EligibilityService,
            loan_recommendation_service_1.LoanRecommendationService,
            sop_analysis_service_1.SopAnalysisService,
            grade_conversion_service_1.GradeConversionService,
            university_comparison_service_1.UniversityComparisonService,
            admit_predictor_service_1.AdmitPredictorService,
            document_verification_service_1.DocumentVerificationService,
            application_review_service_1.ApplicationReviewService,
            university_search_service_1.UniversitySearchService,
            visa_interview_service_1.VisaInterviewService,
            kyc_service_1.KycService,
        ],
    })
], AiModule);
//# sourceMappingURL=ai.module.js.map