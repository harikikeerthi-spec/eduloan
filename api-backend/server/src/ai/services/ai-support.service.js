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
var AiSupportService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiSupportService = void 0;
const common_1 = require("@nestjs/common");
const open_router_service_1 = require("./open-router.service");
let AiSupportService = AiSupportService_1 = class AiSupportService {
    openRouterService;
    logger = new common_1.Logger(AiSupportService_1.name);
    constructor(openRouterService) {
        this.openRouterService = openRouterService;
    }
    async getResponse(userMessage) {
        const systemPrompt = `You are the VidhyaLoan AI Assistant, a helpful and knowledgeable support bot for an education loan application app.
    Your goal is to assist users with questions about loans, eligibility, documentation, and the application process.
    
    Key Information about VidhyaLoan:
    - Interest Rates: Start from 8.5% for international studies and 9% for domestic studies.
    - Documents Required: ID Proof, Academic Records, Admission Letter, Income Proof (Co-applicant).
    - Features: We have an 'Eligibility Checker', 'EMI Calculator', 'Admit Predictor', and 'University Comparator'.
    - Contact: Human support is available at support@vidhyaloan.com or +1-800-VIDHYA-LOAN.

    Guidelines:
    - Be polite, professional, and concise (keep answers under 3-4 sentences if possible).
    - If you are unsure, suggest checking the specific tool in the app or contacting support.
    - Do not make up false policies.
    - Encourage users to apply for a loan if they seem interested.
    `;
        try {
            return await this.openRouterService.generateResponse(systemPrompt, userMessage);
        }
        catch (error) {
            this.logger.error('Failed to generate support response', error);
            return "I'm currently having trouble connecting to my brain. Please try again or contact human support.";
        }
    }
};
exports.AiSupportService = AiSupportService;
exports.AiSupportService = AiSupportService = AiSupportService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [open_router_service_1.OpenRouterService])
], AiSupportService);
//# sourceMappingURL=ai-support.service.js.map