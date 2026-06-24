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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiController = void 0;
const common_1 = require("@nestjs/common");
const eligibility_service_1 = require("./services/eligibility.service");
const loan_recommendation_service_1 = require("./services/loan-recommendation.service");
const sop_analysis_service_1 = require("./services/sop-analysis.service");
const grade_conversion_service_1 = require("./services/grade-conversion.service");
const university_comparison_service_1 = require("./services/university-comparison.service");
const admit_predictor_service_1 = require("./services/admit-predictor.service");
const openrouter_service_1 = require("./services/openrouter.service");
const university_search_service_1 = require("./services/university-search.service");
const visa_interview_service_1 = require("./services/visa-interview.service");
const supabase_service_1 = require("../supabase/supabase.service");
let AiController = class AiController {
    eligibilityService;
    loanRecommendationService;
    sopAnalysisService;
    gradeConversionService;
    universityComparisonService;
    admitPredictorService;
    openRouterService;
    universitySearchService;
    visaInterviewService;
    supabase;
    constructor(eligibilityService, loanRecommendationService, sopAnalysisService, gradeConversionService, universityComparisonService, admitPredictorService, openRouterService, universitySearchService, visaInterviewService, supabase) {
        this.eligibilityService = eligibilityService;
        this.loanRecommendationService = loanRecommendationService;
        this.sopAnalysisService = sopAnalysisService;
        this.gradeConversionService = gradeConversionService;
        this.universityComparisonService = universityComparisonService;
        this.admitPredictorService = admitPredictorService;
        this.openRouterService = openRouterService;
        this.universitySearchService = universitySearchService;
        this.visaInterviewService = visaInterviewService;
        this.supabase = supabase;
    }
    async checkEligibility(data) {
        const eligibilityResult = await this.eligibilityService.calculateEligibilityScore(data);
        const loanRecommendations = await this.loanRecommendationService.recommendLoans(eligibilityResult.score, data.credit, eligibilityResult.ratio, data.loan, data.coApplicant, data.collateral, data.study);
        try {
            await this.eligibilityService.saveLog({
                age: Number(data.age) || 0,
                credit: Number(data.credit) || 0,
                income: Number(data.income) || 0,
                loan: Number(data.loan) || 0,
                employment: String(data.employment || 'unknown'),
                study: String(data.study || 'unknown'),
                coApplicant: String(data.coApplicant || 'no'),
                collateral: String(data.collateral || 'no'),
                score: eligibilityResult.score,
                status: eligibilityResult.status,
                rateRange: eligibilityResult.rateRange,
                coverage: eligibilityResult.coverage,
                recommendations: loanRecommendations,
                userId: data.userId || null,
            });
        }
        catch (e) {
            console.error('Failed to save loan eligibility record:', e);
        }
        return {
            success: true,
            eligibility: eligibilityResult,
            recommendations: loanRecommendations,
        };
    }
    async getLoanRecommendations(data) {
        const credit = 720;
        const loan = Number(data.loanAmount) || Number(data.loan) || 1500000;
        const income = Number(data.cosignerIncome) || 800000;
        const coApplicant = (data.cosignerRelation && data.cosignerRelation !== 'None') ? 'yes' : 'no';
        const collateral = (Number(data.collateralValue) > 0 || data.claimCollateral === 'Yes') ? 'yes' : 'no';
        let employment = 'employed';
        if (data.cosignerType) {
            const type = data.cosignerType.toLowerCase();
            if (type.includes('self')) {
                employment = 'self';
            }
            else if (type.includes('salaried') || type.includes('employed')) {
                employment = 'employed';
            }
            else if (type.includes('farmer') || type.includes('pensioner')) {
                employment = 'employed';
            }
        }
        const study = (data.degree && data.degree.toLowerCase().includes('bachelor')) ? 'undergrad' : 'masters';
        const eligibilityResult = await this.eligibilityService.calculateEligibilityScore({
            age: 23,
            credit,
            income,
            loan,
            employment,
            study,
            coApplicant,
            collateral,
        });
        const serviceRecommendations = await this.loanRecommendationService.recommendLoans(eligibilityResult.score, credit, eligibilityResult.ratio, loan, coApplicant, collateral, study);
        const formatRupees = (val) => {
            return '₹' + val.toLocaleString('en-IN');
        };
        const mapOffer = (offer) => {
            const formattedAmount = offer.maxLoan ? formatRupees(offer.maxLoan) : formatRupees(loan);
            return {
                ...offer,
                rate: offer.apr || '9.5%',
                amount: formattedAmount,
                processingTime: offer.processingTime || '3-5 Days',
                savings: offer.savings || '₹15,000 on processing fee',
            };
        };
        const mappedPrimary = {
            offer: mapOffer(serviceRecommendations.primary.offer),
            fit: serviceRecommendations.primary.fit,
        };
        const mappedAlternatives = serviceRecommendations.alternatives.map((alt) => ({
            offer: mapOffer(alt.offer),
            fit: alt.fit,
        }));
        return {
            primary: mappedPrimary,
            alternatives: mappedAlternatives,
        };
    }
    async analyzeSop(data) {
        const sopText = data.text || data.sop || '';
        const result = await this.sopAnalysisService.analyzeSop(sopText);
        return {
            success: true,
            analysis: result,
        };
    }
    async humanizeSop(data) {
        const result = await this.sopAnalysisService.humanizeSop(data.text);
        return {
            success: true,
            ...result,
        };
    }
    async convertGrades(data) {
        const result = await this.gradeConversionService.convertGrade(data);
        return {
            success: true,
            gradeConversion: result,
        };
    }
    async analyzeGrades(data) {
        const marks = data.marks || [];
        const totalPerSubject = data.totalMarks || 100;
        if (marks.length > 0) {
            for (const m of marks) {
                if (typeof m !== 'number' || isNaN(m) || m < 0 || m > totalPerSubject) {
                    throw new common_1.BadRequestException(`Each mark must be a number between 0 and ${totalPerSubject}`);
                }
            }
        }
        const percentage = marks.length
            ? (marks.reduce((a, b) => a + b, 0) / (marks.length * totalPerSubject)) * 100
            : (data.percentage ?? 0);
        const result = await this.gradeConversionService.convertGrade({
            inputType: 'percentage',
            inputValue: percentage,
            outputType: 'percentage',
        });
        const analysisData = {
            percentage: result.percentage,
            letterGrade: result.letterGrade,
            classification: result.classification,
            internationalEquivalent: result.internationalEquivalent,
            analysis: result.analysis,
            marksBreakdown: data.subjects
                ? data.subjects.map((subject, index) => ({
                    subject,
                    marks: data.marks?.[index] || 0,
                    outOf: totalPerSubject,
                }))
                : null,
        };
        return {
            success: true,
            gradeAnalysis: analysisData,
        };
    }
    async compareGrades(data) {
        const result = await this.gradeConversionService.comparePerformance(data.assessments);
        return {
            success: true,
            comparison: result,
        };
    }
    async compareUniversities(data) {
        const result = await this.universityComparisonService.compare(data.uni1, data.uni2, data.program1, data.program2);
        return {
            success: true,
            data: result,
        };
    }
    async compareShortlist(data) {
        const result = await this.universityComparisonService.compareShortlist(data.shortlist, data.profile);
        return {
            success: true,
            data: result,
        };
    }
    async predictAdmission(body) {
        const profile = body.profile || body;
        if (!profile.targetUniversity) {
            profile.targetUniversity = body.university || body.targetUniversity || '';
        }
        const result = await this.admitPredictorService.predict(profile);
        return {
            success: true,
            prediction: result
        };
    }
    async checkRelevance(data) {
        const topicContext = data.topic || data.title || 'General Discussion';
        const contentToVerify = data.content || data.title || '';
        const prompt = `You are an AI moderator for a student community focused on international education and loans.
    Your goal is to ALLOW any content that is HELPFUL, RELEVANT, or EVEN LOOSELY RELATED to the following topics:
    - Education Loans (Eligibility, Application, Benefits, Interest Rates, EMI, Banks, NBFCs, etc.)
    - Study Abroad (Planning, Countries, Universities, Life as a student, Accommodation, etc.)
    - Admission Processes and Applications (SOP, LOR, Transcripts, GPA, etc.)
    - **Standardized Tests & Exam Preparation** (GRE, GMAT, SAT, IELTS, TOEFL, PTE, Duolingo, etc.)
      - This INCLUDES: exam eligibility, requirements, scores, preparation tips, study plans, coaching, mock tests, exam schedules, registration, cutoffs, percentiles, retakes, verbal/quant/analytical sections, test centers, etc.
      - Questions like "What are the requirements for GRE?" or "How to prepare for GMAT?" are ABSOLUTELY ALLOWED.
    - Visa Processes and Immigration (F1, H1B, OPT, CPT, DS-160, Embassy, etc.)
    - Scholarships, Financial Aid, and Funding
    - Career Discussions for Students (Internships, Placements, Work Permits, etc.)
    - Student Life, Housing, and Practical Tips for Study Abroad

    IMPORTANT: When in doubt, ALLOW the content. Only reject if the content is completely unrelated to education, student life, or careers (e.g., recipes, sports scores, entertainment gossip, politics).

    Context: "${topicContext}"
    Title/Content: "${contentToVerify}"

    Does this content belong in an education/loan/student community?

    Respond with strictly valid JSON:
    {
       "relevant": boolean,
       "reason": "Short explanation if rejected (optional)"
    }`;
        try {
            const result = await this.openRouterService.getJson(prompt);
            return {
                success: true,
                relevant: result.relevant,
                isRelevant: result.relevant,
                reason: result.reason
            };
        }
        catch (error) {
            console.error("AI Check Failed", error);
            return { success: true, relevant: true, isRelevant: true, reason: "AI Check Skipped due to error" };
        }
    }
    async search(data) {
        try {
            const type = data.type || 'university';
            const query = data.query || '';
            const country = data.country || data.context?.country;
            const course = data.course || data.context?.course;
            console.log(`AI Search requested: type=${type}, query="${query}", country=${country}`);
            if (type === 'university' && !query && country) {
                const searchCountry = country === 'India' ? 'USA' : country;
                const universities = await this.universitySearchService.searchUniversitiesByCountry([searchCountry], 12);
                return { success: true, universities };
            }
            const results = await this.openRouterService.searchAdvice(query, type, data.context || data);
            if (type === 'university') {
                return { success: true, universities: results };
            }
            return { success: true, results };
        }
        catch (error) {
            console.error("AI Unified Search Failed", error);
            return { success: false, message: "Search failed", results: [], universities: [] };
        }
    }
    async searchAdvice(data) {
        try {
            const results = await this.openRouterService.searchAdvice(data.query, data.type, data.context);
            return { success: true, results };
        }
        catch (error) {
            console.error("AI Search Failed", error);
            return { success: false, message: "Search failed", results: [] };
        }
    }
    async suggestTags(data) {
        const prompt = `Based on the following forum post title, suggest up to 5 relevant tags that would help categorize this post in a student education and loan community. Focus on specific topics like universities, loans, visas, tests, etc.

    Title: "${data.title}"

    Respond with strictly valid JSON:
    {
       "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
    }`;
        try {
            const result = await this.openRouterService.getJson(prompt);
            return { success: true, tags: result.tags || [] };
        }
        catch (error) {
            console.error("AI Tag Suggestion Failed", error);
            return { success: false, tags: ['education', 'loan'] };
        }
    }
    async searchUniversities(data) {
        try {
            if (data && typeof data.query === 'string') {
                const degree = data.degree || "Master's";
                const country = data.country;
                const type = (degree === "Bachelor's" || degree === 'bachelors' || degree === 'ug_university' || (country === 'India' && degree !== "Master's"))
                    ? 'ug_university'
                    : 'university';
                const context = {
                    country,
                    degree,
                };
                const universities = await this.openRouterService.searchAdvice(data.query, type, context);
                const formatted = (universities || []).map((uni) => ({
                    ...uni,
                    location: uni.loc || uni.location || '',
                    country: type === 'ug_university' ? 'India' : (uni.country || country || ''),
                }));
                return {
                    success: true,
                    universities: formatted,
                    totalCount: formatted.length,
                    source: 'ai',
                };
            }
            let countries = data.countries;
            if (!countries && data.country) {
                countries = [data.country];
            }
            if (!countries || countries.length === 0) {
                throw new common_1.BadRequestException('At least one country is required');
            }
            const universities = await this.universitySearchService.searchUniversitiesByCountry(countries, data.limit || 10);
            const validUniversities = await this.universitySearchService.validateUniversityRealness(universities);
            const formatted = (validUniversities || []).map((uni) => ({
                ...uni,
                location: uni.loc || uni.location || '',
            }));
            return {
                success: true,
                universities: formatted,
                totalCount: formatted.length,
                source: 'ai',
            };
        }
        catch (error) {
            console.error('University search failed:', error);
            return {
                success: false,
                message: error.message || 'Failed to search universities',
                universities: [],
                totalCount: 0,
                source: 'ai',
            };
        }
    }
    async searchCourses(data) {
        try {
            const query = data.query || '';
            const context = {
                university: data.university,
                degree: data.degree,
            };
            const results = await this.openRouterService.searchAdvice(query, 'course', context);
            return {
                success: true,
                courses: results || [],
            };
        }
        catch (error) {
            console.error('Course search failed:', error);
            return {
                success: false,
                courses: [],
            };
        }
    }
    async getUniversityDetails(name, country) {
        try {
            if (!name || !country) {
                throw new common_1.BadRequestException('University name and country are required');
            }
            const details = await this.universitySearchService.getUniversityDetailsFull(name, country);
            return {
                success: true,
                details,
            };
        }
        catch (error) {
            console.error('Failed to fetch university details:', error);
            return {
                success: false,
                message: error.message || 'Failed to fetch university details',
                details: null,
            };
        }
    }
    async getPopularCountries() {
        try {
            const countries = await this.universitySearchService.getPopularCountries();
            return {
                success: true,
                countries,
            };
        }
        catch (error) {
            console.error('Failed to fetch popular countries:', error);
            return {
                success: false,
                message: 'Failed to fetch popular countries',
                countries: [],
            };
        }
    }
    async startVisaInterview(data) {
        try {
            const result = await this.visaInterviewService.startInterview(data.userProfile || {}, data.visaType || 'F1 Student Visa', data.agentType || 'agent_michael');
            return {
                success: true,
                question: result.question,
                currentSection: result.currentSection || 'purpose',
                completedSections: result.completedSections || [],
                isInterviewOver: result.isInterviewOver || false,
                sections: this.visaInterviewService.getSections(),
            };
        }
        catch (error) {
            console.error('Visa interview start failed:', error);
            return { success: false, message: error.message || 'Failed to start interview' };
        }
    }
    async continueVisaInterview(data) {
        try {
            const result = await this.visaInterviewService.continueInterview(data.userProfile || {}, data.visaType || 'F1 Student Visa', data.previousQuestion, data.transcript, data.currentSection, data.conversationHistory || [], data.agentType || 'agent_michael');
            return {
                success: true,
                question: result.question,
                currentSection: result.currentSection,
                completedSections: result.completedSections,
                isInterviewOver: result.isInterviewOver,
            };
        }
        catch (error) {
            console.error('Visa interview continue failed:', error);
            return { success: false, message: error.message || 'Failed to continue interview' };
        }
    }
    async evaluateVisaAnswer(data) {
        try {
            const evaluation = await this.visaInterviewService.evaluateAnswer(data.visaType || 'F1 Student Visa', data.question, data.transcript);
            return { success: true, evaluation };
        }
        catch (error) {
            console.error('Visa answer evaluation failed:', error);
            return { success: false, message: error.message || 'Failed to evaluate answer' };
        }
    }
    async getVisaFinalReport(data) {
        try {
            const report = await this.visaInterviewService.generateFinalReport(data.visaType || 'F1 Student Visa', data.conversationHistory || [], data.evaluations || []);
            return { success: true, report };
        }
        catch (error) {
            console.error('Final report generation failed:', error);
            return { success: false, message: error.message || 'Failed to generate report' };
        }
    }
    async saveVisaReport(data) {
        try {
            const { data: result, error } = await this.supabase.getClient().from('VisaMockInterviewResult').insert({
                userId: data.userId || null,
                visaType: data.visaType,
                agentType: data.agentType || null,
                userProfile: data.userProfile || null,
                overallScore: data.overallScore,
                overallRisk: data.overallRisk,
                approvalLikelihood: data.approvalLikelihood,
                sectionScores: data.sectionScores || {},
                strengths: data.strengths || [],
                weaknesses: data.weaknesses || [],
                criticalIssues: data.criticalIssues || [],
                ds160Inconsistencies: data.ds160Inconsistencies || [],
                tips: data.tips || [],
                verdict: data.verdict || '',
                messages: data.messages || [],
                evaluations: data.evaluations || [],
            }).select().single();
            if (error)
                throw error;
            return { success: true, result };
        }
        catch (error) {
            console.error('Failed to save visa interview result:', error);
            return { success: false, message: 'Failed to save result' };
        }
    }
    async shortlist(data) {
        const { profile, userId, messages } = data;
        if (!profile) {
            throw new common_1.BadRequestException('Profile is required');
        }
        const isEvaluate = profile.selectedUniversities && profile.selectedUniversities.length > 0;
        let systemPrompt = '';
        let userPrompt = '';
        if (isEvaluate) {
            systemPrompt = `You are an expert AI university admission consultant.
The student has a profile and has shortlisted a set of universities they want to evaluate.
Evaluate their chances of admission (Safe, Reach, or Moderate) and provide feedback for each shortlisted university.

Response MUST be strictly valid JSON in the following format:
{
  "recommendations": [
    {
      "name": "University Name",
      "chance": "Safe/Reach/Moderate",
      "type": "Public/Private",
      "rank": "QS or US News Rank (integer as string)",
      "tuition": "Annual Tuition fee in USD (integer as string, e.g. 35000)",
      "location": "City, State/Country",
      "reason": "Clear explanation of why this chance was assigned based on their CGPA, tests, and backlogs",
      "avgSalary": "Average starting salary in USD (integer as string, e.g. 95000)",
      "deadline": "Upcoming main deadline (e.g. Dec 15 / Jan 15)",
      "flag": "Country flag emoji, e.g. 🇺🇸 or 🇨🇦",
      "country": "Country name",
      "programName": "Suggested matching program name",
      "description": "Short summary of the program/university",
      "roi": "High/Medium/Low",
      "acceptanceRate": "Acceptance rate percentage (integer as string, e.g. 25)",
      "duration": "Program duration (e.g. 2 years)",
      "category": "Safe/Reach/Moderate"
    }
  ]
}`;
            userPrompt = `Student Profile:
- Target Degree: ${profile.degree || "Master's"}
- Target Major/Field: ${profile.major || 'Computer Science'}
- CGPA: ${profile.gpa || 'N/A'}
- Backlogs: ${profile.backlogs === 'Yes' ? (profile.backlogCount || 'Yes') : 'No'}
- Test Scores: ${profile.tests || 'None'}
- Work Experience: ${profile.experience || 'None'}

Shortlisted Universities to Evaluate:
${JSON.stringify(profile.selectedUniversities)}`;
        }
        else {
            systemPrompt = `You are an expert AI university shortlister.
Based on the student's profile, recommend the top 6-8 matching universities in their target country.
Categorize them into:
- Safe (highly likely admission, GPA/scores well above average)
- Moderate (good fit, standard chance)
- Reach (ambitious, highly competitive)

Response MUST be strictly valid JSON in the following format:
{
  "recommendations": [
    {
      "name": "University Name",
      "chance": "Safe/Reach/Moderate",
      "type": "Public/Private",
      "rank": "QS or US News Rank (integer as string)",
      "tuition": "Annual Tuition fee in USD (integer as string, e.g. 35000)",
      "location": "City, State/Country",
      "reason": "Clear explanation of why this is a Safe/Moderate/Reach choice for their specific CGPA, tests, and backlogs",
      "avgSalary": "Average starting salary in USD (integer as string, e.g. 95000)",
      "deadline": "Upcoming main deadline (e.g. Dec 15 / Jan 15)",
      "flag": "Country flag emoji, e.g. 🇺🇸 or 🇨🇦",
      "country": "Country name",
      "programName": "Suggested matching program name",
      "description": "Short summary of the program/university",
      "roi": "High/Medium/Low",
      "acceptanceRate": "Acceptance rate percentage (integer as string, e.g. 25)",
      "duration": "Program duration (e.g. 2 years)",
      "category": "Safe/Reach/Moderate"
    }
  ]
}`;
            userPrompt = `Student Profile:
- Target Degree: ${profile.degree || "Master's"}
- Target Country: ${profile.country || 'USA'}
- Target Major/Field: ${profile.major || 'Computer Science'}
- CGPA: ${profile.gpa || 'N/A'}
- Backlogs: ${profile.backlogs === 'Yes' ? (profile.backlogCount || 'Yes') : 'No'}
- Test Scores: ${profile.tests || 'None'}
- Work Experience: ${profile.experience || 'None'}`;
        }
        try {
            const prompt = `${systemPrompt}\n\nUser Profile & Request:\n${userPrompt}`;
            const response = await this.openRouterService.getJson(prompt, 'openai/gpt-4o-mini');
            const recommendations = response?.recommendations || [];
            if (userId) {
                const client = this.supabase.getClient();
                const { data: existing } = await client
                    .from('UniversityShortlistChat')
                    .select('id')
                    .eq('userId', userId)
                    .maybeSingle();
                if (existing) {
                    await client
                        .from('UniversityShortlistChat')
                        .update({
                        messages: messages || [],
                        recommendations: recommendations,
                        updatedAt: new Date().toISOString(),
                    })
                        .eq('userId', userId);
                }
                else {
                    await client
                        .from('UniversityShortlistChat')
                        .insert({
                        userId,
                        messages: messages || [],
                        recommendations: recommendations,
                    });
                }
            }
            return {
                success: true,
                recommendations,
            };
        }
        catch (error) {
            console.error('[AiController.shortlist] Error generating shortlist:', error);
            throw new common_1.BadRequestException('Failed to generate university shortlist: ' + error.message);
        }
    }
    async getShortlistChat(userId) {
        if (!userId) {
            throw new common_1.BadRequestException('User ID is required');
        }
        try {
            const client = this.supabase.getClient();
            const { data, error } = await client
                .from('UniversityShortlistChat')
                .select('*')
                .eq('userId', userId)
                .maybeSingle();
            if (error) {
                throw error;
            }
            return {
                success: true,
                chat: data,
            };
        }
        catch (error) {
            console.error('[AiController.getShortlistChat] Error fetching shortlist chat:', error);
            return {
                success: false,
                message: 'Failed to fetch shortlist chat history',
            };
        }
    }
};
exports.AiController = AiController;
__decorate([
    (0, common_1.Post)('eligibility-check'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "checkEligibility", null);
__decorate([
    (0, common_1.Post)('loan-recommendations'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "getLoanRecommendations", null);
__decorate([
    (0, common_1.Post)('sop-analysis'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "analyzeSop", null);
__decorate([
    (0, common_1.Post)('humanize-sop'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "humanizeSop", null);
__decorate([
    (0, common_1.Post)('convert-grades'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "convertGrades", null);
__decorate([
    (0, common_1.Post)('analyze-grades'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "analyzeGrades", null);
__decorate([
    (0, common_1.Post)('compare-grades'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "compareGrades", null);
__decorate([
    (0, common_1.Post)('compare-universities'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "compareUniversities", null);
__decorate([
    (0, common_1.Post)('compare-shortlist'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "compareShortlist", null);
__decorate([
    (0, common_1.Post)('predict-admission'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "predictAdmission", null);
__decorate([
    (0, common_1.Post)('check-relevance'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "checkRelevance", null);
__decorate([
    (0, common_1.Post)('search'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "search", null);
__decorate([
    (0, common_1.Post)('search-advice'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "searchAdvice", null);
__decorate([
    (0, common_1.Post)('suggest-tags'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "suggestTags", null);
__decorate([
    (0, common_1.Post)('search-universities'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "searchUniversities", null);
__decorate([
    (0, common_1.Post)('search-courses'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "searchCourses", null);
__decorate([
    (0, common_1.Get)('university-details/:name/:country'),
    __param(0, (0, common_1.Param)('name')),
    __param(1, (0, common_1.Param)('country')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "getUniversityDetails", null);
__decorate([
    (0, common_1.Get)('popular-countries'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AiController.prototype, "getPopularCountries", null);
__decorate([
    (0, common_1.Post)('visa-interview/start'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "startVisaInterview", null);
__decorate([
    (0, common_1.Post)('visa-interview/continue'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "continueVisaInterview", null);
__decorate([
    (0, common_1.Post)('visa-interview/evaluate'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "evaluateVisaAnswer", null);
__decorate([
    (0, common_1.Post)('visa-interview/final-report'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "getVisaFinalReport", null);
__decorate([
    (0, common_1.Post)('visa-interview/save-report'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "saveVisaReport", null);
__decorate([
    (0, common_1.Post)('shortlist'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "shortlist", null);
__decorate([
    (0, common_1.Get)('shortlist/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "getShortlistChat", null);
exports.AiController = AiController = __decorate([
    (0, common_1.Controller)('ai'),
    __metadata("design:paramtypes", [eligibility_service_1.EligibilityService,
        loan_recommendation_service_1.LoanRecommendationService,
        sop_analysis_service_1.SopAnalysisService,
        grade_conversion_service_1.GradeConversionService,
        university_comparison_service_1.UniversityComparisonService,
        admit_predictor_service_1.AdmitPredictorService,
        openrouter_service_1.OpenRouterService,
        university_search_service_1.UniversitySearchService,
        visa_interview_service_1.VisaInterviewService,
        supabase_service_1.SupabaseService])
], AiController);
//# sourceMappingURL=ai.controller.js.map