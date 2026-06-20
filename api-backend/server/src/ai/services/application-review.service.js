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
exports.ApplicationReviewService = void 0;
const common_1 = require("@nestjs/common");
const openrouter_service_1 = require("./openrouter.service");
let ApplicationReviewService = class ApplicationReviewService {
    openRouter;
    constructor(openRouter) {
        this.openRouter = openRouter;
    }
    async reviewApplication(application, documents) {
        const completeness = this.checkCompleteness(application);
        const documentCheck = this.checkDocuments(documents);
        const basicCreditCheck = this.basicCreditAssessment(application);
        const aiAnalysis = await this.performAIAnalysis(application, completeness, documentCheck, basicCreditCheck);
        const mentorReview = this.determineMentorReview(aiAnalysis, completeness, documentCheck);
        return {
            ...aiAnalysis,
            completenessCheck: completeness,
            documentCheck,
            creditAssessment: {
                ...basicCreditCheck,
                ...aiAnalysis.creditAssessment,
            },
            mentorReviewRequired: mentorReview.required,
            mentorReviewReasons: mentorReview.reasons,
        };
    }
    checkCompleteness(app) {
        const requiredFields = [
            { key: 'firstName', label: 'First Name' },
            { key: 'lastName', label: 'Last Name' },
            { key: 'email', label: 'Email' },
            { key: 'phone', label: 'Phone Number' },
            { key: 'dateOfBirth', label: 'Date of Birth' },
            { key: 'address', label: 'Address' },
            { key: 'bank', label: 'Bank' },
            { key: 'loanType', label: 'Loan Type' },
            { key: 'amount', label: 'Loan Amount' },
            { key: 'universityName', label: 'University Name' },
            { key: 'courseName', label: 'Course Name' },
            { key: 'country', label: 'Country' },
        ];
        const conditionalFields = [
            { key: 'coApplicantName', label: 'Co-Applicant Name', condition: app.hasCoApplicant },
            { key: 'coApplicantRelation', label: 'Co-Applicant Relation', condition: app.hasCoApplicant },
            { key: 'coApplicantIncome', label: 'Co-Applicant Income', condition: app.hasCoApplicant },
            { key: 'collateralType', label: 'Collateral Type', condition: app.hasCollateral },
            { key: 'collateralValue', label: 'Collateral Value', condition: app.hasCollateral },
        ];
        const allFields = [
            ...requiredFields,
            ...conditionalFields.filter(f => f.condition),
        ];
        const filled = allFields.filter(f => {
            const val = app[f.key];
            return val !== null && val !== undefined && val !== '';
        });
        const missing = allFields.filter(f => {
            const val = app[f.key];
            return val === null || val === undefined || val === '';
        });
        return {
            score: allFields.length > 0 ? Math.round((filled.length / allFields.length) * 100) : 0,
            missingFields: missing.map(f => f.label),
            filledFields: filled.map(f => f.label),
            percentage: allFields.length > 0 ? Math.round((filled.length / allFields.length) * 100) : 0,
        };
    }
    checkDocuments(documents) {
        const totalRequired = documents.filter(d => d.isRequired).length;
        const uploaded = documents.filter(d => d.filePath && d.filePath !== '').length;
        const verified = documents.filter(d => d.status === 'verified').length;
        const pending = documents.filter(d => d.status === 'pending' && d.filePath).length;
        const rejected = documents.filter(d => d.status === 'rejected').length;
        let status = 'missing';
        if (uploaded >= totalRequired && totalRequired > 0)
            status = 'complete';
        else if (uploaded > 0)
            status = 'partial';
        return {
            totalRequired: Math.max(totalRequired, documents.length),
            uploaded,
            verified,
            pending: pending + rejected,
            status,
        };
    }
    basicCreditAssessment(app) {
        const amount = app.amount || 0;
        const income = app.annualIncome || app.coApplicantIncome || 0;
        const incomeToLoanRatio = income > 0 ? Number((income / amount).toFixed(2)) : 0;
        let riskLevel = 'medium';
        const observations = [];
        if (incomeToLoanRatio > 2) {
            riskLevel = 'low';
            observations.push('Income is more than 2x the loan amount — low risk');
        }
        else if (incomeToLoanRatio > 0.5) {
            riskLevel = 'medium';
            observations.push('Moderate income-to-loan ratio');
        }
        else if (income > 0) {
            riskLevel = 'high';
            observations.push('Low income relative to loan amount — high risk');
        }
        else {
            observations.push('No income information provided');
        }
        if (app.hasCoApplicant) {
            observations.push('Has co-applicant — additional income source');
            if (riskLevel === 'high')
                riskLevel = 'medium';
        }
        if (app.hasCollateral) {
            observations.push(`Has collateral: ${app.collateralType || 'Yes'}`);
            if (riskLevel === 'high')
                riskLevel = 'medium';
        }
        if (amount > 5000000) {
            observations.push('High loan amount (>₹50 lakhs)');
        }
        return { riskLevel, incomeToLoanRatio, observations };
    }
    async performAIAnalysis(app, completeness, documentCheck, creditCheck) {
        const prompt = `
You are a senior loan officer AI assistant for an education loan platform. Analyze this loan application and provide a thorough review.

APPLICATION DETAILS:
- Applicant: ${app.firstName || '—'} ${app.lastName || '—'}
- Email: ${app.email || '—'}
- Phone: ${app.phone || '—'}
- DOB: ${app.dateOfBirth || '—'}
- Address: ${app.address || '—'}, ${app.city || ''}, ${app.state || ''}, ${app.country || ''}

LOAN DETAILS:
- Bank: ${app.bank || '—'}
- Loan Type: ${app.loanType || '—'}
- Amount: ₹${app.amount?.toLocaleString() || 0}
- Tenure: ${app.tenure || '—'} months
- Purpose: ${app.purpose || '—'}

EDUCATION:
- University: ${app.universityName || '—'}
- Course: ${app.courseName || '—'}
- Duration: ${app.courseDuration || '—'} years
- Country: ${app.country || '—'}
- Admission Status: ${app.admissionStatus || '—'}

EMPLOYMENT:
- Type: ${app.employmentType || '—'}
- Employer: ${app.employerName || '—'}
- Annual Income: ₹${app.annualIncome?.toLocaleString() || '—'}

CO-APPLICANT: ${app.hasCoApplicant ? `Yes — ${app.coApplicantRelation || '—'}, Income: ₹${app.coApplicantIncome?.toLocaleString() || '—'}` : 'None'}
COLLATERAL: ${app.hasCollateral ? `Yes — ${app.collateralType || '—'}, Value: ₹${app.collateralValue?.toLocaleString() || '—'}` : 'None'}

COMPLETENESS: ${completeness.percentage}% (Missing: ${completeness.missingFields.join(', ') || 'None'})
DOCUMENTS: ${documentCheck.uploaded}/${documentCheck.totalRequired} uploaded, ${documentCheck.verified} verified
CREDIT A/S: Risk=${creditCheck.riskLevel}, Income-to-Loan Ratio=${creditCheck.incomeToLoanRatio}

Analyze strictly and return JSON:
{
  "overallScore": <number 0-100>,
  "recommendation": "<approve|reject|needs_review>",
  "creditAssessment": {
    "riskLevel": "<low|medium|high>",
    "incomeToLoanRatio": <number>,
    "observations": ["<string>"]
  },
  "eligibilityFlags": [
    { "flag": "<name>", "status": "<pass|warning|fail>", "detail": "<explanation>" }
  ],
  "aiSummary": "<2-3 sentence professional summary of your analysis>",
  "aiRecommendations": ["<actionable recommendation>"]
}

Rules:
- If completeness < 70%, recommendation should be "needs_review"
- If documents are "missing", recommendation should be "needs_review"
- Be strict about missing critical fields (name, email, amount, bank)
- Consider the university reputation and country for education loans
- Flag any inconsistencies
`;
        try {
            console.log(`[ApplicationReviewService] Sending prompt to OpenRouter for application review...`);
            const result = await this.openRouter.getJson(prompt);
            console.log(`[ApplicationReviewService] Received AI response:`, JSON.stringify(result).substring(0, 200) + '...');
            if (!result || typeof result !== 'object') {
                throw new Error('AI returned an empty or invalid response object');
            }
            const safeResult = {
                overallScore: typeof result.overallScore === 'number' ? result.overallScore : (completeness.percentage > 80 ? 70 : 40),
                recommendation: (result.recommendation === 'approve' || result.recommendation === 'reject' || result.recommendation === 'needs_review')
                    ? result.recommendation
                    : 'needs_review',
                creditAssessment: {
                    riskLevel: result.creditAssessment?.riskLevel || creditCheck.riskLevel,
                    incomeToLoanRatio: result.creditAssessment?.incomeToLoanRatio || creditCheck.incomeToLoanRatio,
                    observations: Array.isArray(result.creditAssessment?.observations)
                        ? result.creditAssessment.observations
                        : [],
                },
                eligibilityFlags: Array.isArray(result.eligibilityFlags) ? result.eligibilityFlags : [],
                aiSummary: result.aiSummary || 'Analysis completed based on available data.',
                aiRecommendations: Array.isArray(result.aiRecommendations) ? result.aiRecommendations : [],
            };
            return {
                ...safeResult,
                completenessCheck: completeness,
                documentCheck,
                creditAssessment: {
                    ...safeResult.creditAssessment,
                    observations: [...creditCheck.observations, ...safeResult.creditAssessment.observations],
                },
                mentorReviewRequired: false,
                mentorReviewReasons: [],
            };
        }
        catch (error) {
            console.error('AI Application Review failed:', error);
            return {
                overallScore: completeness.percentage > 80 ? 60 : 30,
                recommendation: completeness.percentage > 80 ? 'needs_review' : 'reject',
                completenessCheck: completeness,
                documentCheck,
                creditAssessment: creditCheck,
                eligibilityFlags: [
                    {
                        flag: 'AI Analysis',
                        status: 'warning',
                        detail: 'AI service was unavailable. Manual review recommended.',
                    },
                ],
                aiSummary: 'AI analysis service is currently unavailable. A manual review by a mentor/admin is recommended.',
                aiRecommendations: ['Perform manual verification of all details', 'Verify documents manually'],
                mentorReviewRequired: true,
                mentorReviewReasons: ['AI analysis was not available — manual review required'],
            };
        }
    }
    determineMentorReview(aiAnalysis, completeness, documentCheck) {
        const reasons = [];
        if (aiAnalysis.recommendation === 'needs_review') {
            reasons.push('AI recommends further review');
        }
        if (completeness.percentage < 80) {
            reasons.push(`Application is only ${completeness.percentage}% complete`);
        }
        if (documentCheck.status !== 'complete') {
            reasons.push('Required documents are not fully uploaded/verified');
        }
        if (aiAnalysis.overallScore < 50) {
            reasons.push('Low overall application score');
        }
        if (aiAnalysis.creditAssessment?.riskLevel === 'high') {
            reasons.push('High credit risk assessment');
        }
        const failFlags = (aiAnalysis.eligibilityFlags || []).filter((f) => f.status === 'fail');
        if (failFlags.length > 0) {
            reasons.push(`${failFlags.length} eligibility flag(s) failed`);
        }
        return {
            required: reasons.length > 0,
            reasons,
        };
    }
};
exports.ApplicationReviewService = ApplicationReviewService;
exports.ApplicationReviewService = ApplicationReviewService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [openrouter_service_1.OpenRouterService])
], ApplicationReviewService);
//# sourceMappingURL=application-review.service.js.map