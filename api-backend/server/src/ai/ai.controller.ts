import { Controller, Post, Body, BadRequestException, Get, Param } from '@nestjs/common';
import { EligibilityService } from './services/eligibility.service';
import { LoanRecommendationService } from './services/loan-recommendation.service';
import { SopAnalysisService } from './services/sop-analysis.service';
import { GradeConversionService } from './services/grade-conversion.service';
import { UniversityComparisonService } from './services/university-comparison.service';
import { AdmitPredictorService } from './services/admit-predictor.service';
import { OpenRouterService } from './services/openrouter.service';
import { UniversitySearchService, University, UniversityDetails } from './services/university-search.service';
import { VisaInterviewService, InterviewMessage, EvaluationResult } from './services/visa-interview.service';
import { SupabaseService } from '../supabase/supabase.service';

@Controller('ai')
export class AiController {
  constructor(
    private readonly eligibilityService: EligibilityService,
    private readonly loanRecommendationService: LoanRecommendationService,
    private readonly sopAnalysisService: SopAnalysisService,
    private readonly gradeConversionService: GradeConversionService,
    private readonly universityComparisonService: UniversityComparisonService,
    private readonly admitPredictorService: AdmitPredictorService,
    private readonly openRouterService: OpenRouterService,
    private readonly universitySearchService: UniversitySearchService,
    private readonly visaInterviewService: VisaInterviewService,
    private readonly supabase: SupabaseService,
  ) { }

  @Post('eligibility-check')
  async checkEligibility(
    @Body()
    data: any,
  ) {
    const eligibilityResult = await this.eligibilityService.calculateEligibilityScore(data);

    const loanRecommendations = await this.loanRecommendationService.recommendLoans(
      eligibilityResult.score,
      data.credit,
      eligibilityResult.ratio,
      data.loan,
      data.coApplicant,
      data.collateral,
      data.study,
    );

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
    } catch (e) {
      console.error('Failed to save loan eligibility record:', e);
    }

    return {
      success: true,
      eligibility: eligibilityResult,
      recommendations: loanRecommendations,
    };
  }

  @Post('loan-recommendations')
  async getLoanRecommendations(
    @Body()
    data: any,
  ) {
    // 1. Map frontend profile parameters to eligibility/recommendations format
    const credit = 720;
    const loan = Number(data.loanAmount) || Number(data.loan) || 1500000;
    const income = Number(data.cosignerIncome) || 800000;
    const coApplicant = (data.cosignerRelation && data.cosignerRelation !== 'None') ? 'yes' : 'no';
    const collateral = (Number(data.collateralValue) > 0 || data.claimCollateral === 'Yes') ? 'yes' : 'no';
    
    let employment: 'employed' | 'self' | 'student' | 'unemployed' = 'employed';
    if (data.cosignerType) {
      const type = data.cosignerType.toLowerCase();
      if (type.includes('self')) {
        employment = 'self';
      } else if (type.includes('salaried') || type.includes('employed')) {
        employment = 'employed';
      } else if (type.includes('farmer') || type.includes('pensioner')) {
        employment = 'employed';
      }
    }

    const study = (data.degree && data.degree.toLowerCase().includes('bachelor')) ? 'undergrad' : 'masters';

    // Calculate eligibility score first
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

    // Get recommendations from service
    const serviceRecommendations = await this.loanRecommendationService.recommendLoans(
      eligibilityResult.score,
      credit,
      eligibilityResult.ratio,
      loan,
      coApplicant,
      collateral,
      study,
    );

    // Helper to format rupees in Indian format
    const formatRupees = (val: number) => {
      return '₹' + val.toLocaleString('en-IN');
    };

    // Helper to map and format service offer to frontend expected fields
    const mapOffer = (offer: any) => {
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

  @Post('sop-analysis')
  async analyzeSop(
    @Body()
    data: {
      text?: string;
      sop?: string;
    },
  ) {
    const sopText = data.text || data.sop || '';
    const result = await this.sopAnalysisService.analyzeSop(sopText);
    return {
      success: true,
      analysis: result,
    };
  }

  @Post('humanize-sop')
  async humanizeSop(
    @Body()
    data: {
      text: string;
    },
  ) {
    const result = await this.sopAnalysisService.humanizeSop(data.text);
    return {
      success: true,
      ...result,
    };
  }

  @Post('convert-grades')
  async convertGrades(
    @Body()
    data: {
      inputType: 'letterGrade' | 'percentage' | 'gpa' | 'cgpa' | 'marks';
      inputValue: string | number;
      totalMarks?: number;
      outputType: 'letterGrade' | 'percentage' | 'gpa' | 'cgpa';
      gradingSystem?: 'US' | 'UK' | 'India' | 'Canada' | 'Australia';
    },
  ): Promise<any> {
    const result = await this.gradeConversionService.convertGrade(data);
    return {
      success: true,
      gradeConversion: result,
    };
  }

  @Post('analyze-grades')
  async analyzeGrades(
    @Body()
    data: {
      marks?: number[];
      subjects?: string[];
      totalMarks?: number;
      gpa?: number;
      percentage?: number;
    },
  ): Promise<any> {
    // Validate marks if provided and compute overall percentage safely
    const marks = data.marks || [];
    const totalPerSubject = data.totalMarks || 100;

    if (marks.length > 0) {
      for (const m of marks) {
        if (typeof m !== 'number' || isNaN(m) || m < 0 || m > totalPerSubject) {
          throw new BadRequestException(`Each mark must be a number between 0 and ${totalPerSubject}`);
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

    // Enhanced analysis with marks breakdown
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

  @Post('compare-grades')
  async compareGrades(
    @Body()
    data: {
      assessments: Array<{
        name: string;
        percentage: number;
      }>;
    },
  ): Promise<any> {
    const result = await this.gradeConversionService.comparePerformance(data.assessments);
    return {
      success: true,
      comparison: result,
    };
  }

  @Post('compare-universities')
  async compareUniversities(
    @Body()
    data: {
      uni1: string;
      uni2: string;
      program1?: string;
      program2?: string;
    },
  ) {
    const result = await this.universityComparisonService.compare(
      data.uni1,
      data.uni2,
      data.program1,
      data.program2
    );
    return {
      success: true,
      data: result,
    };
  }

  @Post('compare-shortlist')
  async compareShortlist(
    @Body()
    data: {
      shortlist: Array<{ name: string; course: string }>;
      profile: { bachelors?: string; workExp?: string; gpa?: string };
    },
  ) {
    const result = await this.universityComparisonService.compareShortlist(
      data.shortlist,
      data.profile
    );
    return {
      success: true,
      data: result,
    };
  }

  @Post('predict-admission')
  async predictAdmission(@Body() body: any) {
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

  @Post('check-relevance')
  async checkRelevance(@Body() data: { topic?: string; title?: string; content: string }) {
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
      const result = await this.openRouterService.getJson<{ relevant: boolean; reason?: string }>(prompt);
      return {
        success: true,
        relevant: result.relevant,
        isRelevant: result.relevant,
        reason: result.reason
      };
    } catch (error) {
      console.error("AI Check Failed", error);
      // Fail permissive if AI is down
      return { success: true, relevant: true, isRelevant: true, reason: "AI Check Skipped due to error" };
    }
  }

  @Post('search')
  async search(@Body() data: any) {
    try {
      const type = data.type || 'university';
      const query = data.query || '';
      const country = data.country || data.context?.country;
      const course = data.course || data.context?.course;

      console.log(`AI Search requested: type=${type}, query="${query}", country=${country}`);

      // Case 1: Fetching top universities for a country (Initial load in onboarding)
      if (type === 'university' && !query && country) {
        const searchCountry = country === 'India' ? 'USA' : country;
        const universities = await this.universitySearchService.searchUniversitiesByCountry([searchCountry], 12);
        return { success: true, universities };
      }

      // Case 2: General advice/search for universities or courses
      const results = await this.openRouterService.searchAdvice(query, type, data.context || data);

      if (type === 'university') {
        return { success: true, universities: results };
      }

      return { success: true, results };
    } catch (error) {
      console.error("AI Unified Search Failed", error);
      return { success: false, message: "Search failed", results: [], universities: [] };
    }
  }

  @Post('search-advice')
  async searchAdvice(@Body() data: { query: string; type: 'university' | 'course' | 'ug_university'; context?: any }) {
    try {
      const results = await this.openRouterService.searchAdvice(data.query, data.type, data.context);
      return { success: true, results };
    } catch (error) {
      console.error("AI Search Failed", error);
      return { success: false, message: "Search failed", results: [] };
    }
  }

  @Post('suggest-tags')
  async suggestTags(@Body() data: { title: string }) {
    const prompt = `Based on the following forum post title, suggest up to 5 relevant tags that would help categorize this post in a student education and loan community. Focus on specific topics like universities, loans, visas, tests, etc.

    Title: "${data.title}"

    Respond with strictly valid JSON:
    {
       "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
    }`;

    try {
      const result = await this.openRouterService.getJson<{ tags: string[] }>(prompt);
      return { success: true, tags: result.tags || [] };
    } catch (error) {
      console.error("AI Tag Suggestion Failed", error);
      return { success: false, tags: ['education', 'loan'] };
    }
  }

  @Post('search-universities')
  async searchUniversities(
    @Body()
    data: any,
  ): Promise<{ success: boolean; universities: any[]; totalCount: number; source: string; message?: string }> {
    try {
      // If query is provided (including empty string)
      if (data && typeof data.query === 'string') {
        const degree = data.degree || "Master's";
        const country = data.country;
        
        // Determine search type: Indian colleges/universities for Bachelor's degree,
        // International universities for Master's/other degrees
        const type = (degree === "Bachelor's" || degree === 'bachelors' || degree === 'ug_university' || (country === 'India' && degree !== "Master's")) 
          ? 'ug_university' 
          : 'university';
          
        const context = {
          country,
          degree,
        };
        
        const universities = await this.openRouterService.searchAdvice(
          data.query,
          type,
          context,
        );

        // Normalize output locations for display on frontend
        const formatted = (universities || []).map((uni: any) => ({
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

      // Fallback: Search by country list
      let countries = data.countries;
      if (!countries && data.country) {
        countries = [data.country];
      }

      if (!countries || countries.length === 0) {
        throw new BadRequestException('At least one country is required');
      }

      const universities = await this.universitySearchService.searchUniversitiesByCountry(
        countries,
        data.limit || 10,
      );

      const validUniversities = await this.universitySearchService.validateUniversityRealness(universities);

      // Normalize locations for fallback search as well
      const formatted = (validUniversities || []).map((uni: any) => ({
        ...uni,
        location: uni.loc || uni.location || '',
      }));

      return {
        success: true,
        universities: formatted,
        totalCount: formatted.length,
        source: 'ai',
      };
    } catch (error) {
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

  @Post('search-courses')
  async searchCourses(
    @Body()
    data: {
      university?: string;
      query: string;
      degree?: string;
    },
  ): Promise<{ success: boolean; courses: any[] }> {
    try {
      const query = data.query || '';
      const context = {
        university: data.university,
        degree: data.degree,
      };
      const results = await this.openRouterService.searchAdvice(
        query,
        'course',
        context,
      );
      return {
        success: true,
        courses: results || [],
      };
    } catch (error) {
      console.error('Course search failed:', error);
      return {
        success: false,
        courses: [],
      };
    }
  }

  @Get('university-details/:name/:country')
  async getUniversityDetails(
    @Param('name') name: string,
    @Param('country') country: string,
  ): Promise<{ success: boolean; details?: UniversityDetails | null; message?: string }> {
    try {
      if (!name || !country) {
        throw new BadRequestException('University name and country are required');
      }

      const details = await this.universitySearchService.getUniversityDetailsFull(name, country);

      return {
        success: true,
        details,
      };
    } catch (error) {
      console.error('Failed to fetch university details:', error);
      return {
        success: false,
        message: error.message || 'Failed to fetch university details',
        details: null,
      };
    }
  }

  @Get('popular-countries')
  async getPopularCountries() {
    try {
      const countries = await this.universitySearchService.getPopularCountries();
      return {
        success: true,
        countries,
      };
    } catch (error) {
      console.error('Failed to fetch popular countries:', error);
      return {
        success: false,
        message: 'Failed to fetch popular countries',
        countries: [],
      };
    }
  }

  // ── Visa Interview Simulator Endpoints ──

  @Post('visa-interview/start')
  async startVisaInterview(
    @Body() data: { userProfile: Record<string, any>; visaType?: string; agentType?: string },
  ) {
    try {
      const result = await this.visaInterviewService.startInterview(
        data.userProfile || {},
        data.visaType || 'F1 Student Visa',
        data.agentType || 'agent_michael'
      );
      return {
        success: true,
        question: result.question,
        currentSection: result.currentSection || 'purpose',
        completedSections: result.completedSections || [],
        isInterviewOver: result.isInterviewOver || false,
        sections: this.visaInterviewService.getSections(),
      };
    } catch (error) {
      console.error('Visa interview start failed:', error);
      return { success: false, message: error.message || 'Failed to start interview' };
    }
  }

  @Post('visa-interview/continue')
  async continueVisaInterview(
    @Body()
    data: {
      userProfile: Record<string, any>;
      visaType?: string;
      agentType?: string;
      previousQuestion: string;
      transcript: string;
      currentSection: string;
      conversationHistory?: InterviewMessage[];
    },
  ) {
    try {
      const result = await this.visaInterviewService.continueInterview(
        data.userProfile || {},
        data.visaType || 'F1 Student Visa',
        data.previousQuestion,
        data.transcript,
        data.currentSection,
        data.conversationHistory || [],
        data.agentType || 'agent_michael',
      );
      return {
        success: true,
        question: result.question,
        currentSection: result.currentSection,
        completedSections: result.completedSections,
        isInterviewOver: result.isInterviewOver,
      };
    } catch (error) {
      console.error('Visa interview continue failed:', error);
      return { success: false, message: error.message || 'Failed to continue interview' };
    }
  }

  @Post('visa-interview/evaluate')
  async evaluateVisaAnswer(
    @Body()
    data: {
      visaType?: string;
      question: string;
      transcript: string;
    },
  ) {
    try {
      const evaluation = await this.visaInterviewService.evaluateAnswer(
        data.visaType || 'F1 Student Visa',
        data.question,
        data.transcript,
      );
      return { success: true, evaluation };
    } catch (error) {
      console.error('Visa answer evaluation failed:', error);
      return { success: false, message: error.message || 'Failed to evaluate answer' };
    }
  }

  @Post('visa-interview/final-report')
  async getVisaFinalReport(
    @Body()
    data: {
      visaType?: string;
      conversationHistory: InterviewMessage[];
      evaluations: EvaluationResult[];
    },
  ) {
    try {
      const report = await this.visaInterviewService.generateFinalReport(
        data.visaType || 'F1 Student Visa',
        data.conversationHistory || [],
        data.evaluations || [],
      );
      return { success: true, report };
    } catch (error) {
      console.error('Final report generation failed:', error);
      return { success: false, message: error.message || 'Failed to generate report' };
    }
  }

  @Post('visa-interview/save-report')
  async saveVisaReport(
    @Body()
    data: {
      userId?: string;
      visaType: string;
      agentType?: string;
      userProfile?: any;
      overallScore: number;
      overallRisk: string;
      approvalLikelihood: string;
      sectionScores: any;
      strengths: string[];
      weaknesses: string[];
      criticalIssues: string[];
      ds160Inconsistencies: string[];
      tips: string[];
      verdict: string;
      messages: any;
      evaluations: any;
    },
  ) {
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
      if (error) throw error;
      return { success: true, result };
    } catch (error) {
      console.error('Failed to save visa interview result:', error);
      return { success: false, message: 'Failed to save result' };
    }
  }

  @Post('shortlist')
  async shortlist(
    @Body()
    data: {
      profile: any;
      userId?: string;
      messages?: any[];
    },
  ) {
    const { profile, userId, messages } = data;
    if (!profile) {
      throw new BadRequestException('Profile is required');
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
    } else {
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
      const response = await this.openRouterService.getJson<{ recommendations: any[] }>(
        prompt,
        'meta-llama/llama-3.3-70b-instruct:free',
      );

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
        } else {
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
    } catch (error) {
      console.error('[AiController.shortlist] Error generating shortlist:', error);
      throw new BadRequestException('Failed to generate university shortlist: ' + error.message);
    }
  }

  @Get('shortlist/:userId')
  async getShortlistChat(@Param('userId') userId: string) {
    if (!userId) {
      throw new BadRequestException('User ID is required');
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
    } catch (error) {
      console.error('[AiController.getShortlistChat] Error fetching shortlist chat:', error);
      return {
        success: false,
        message: 'Failed to fetch shortlist chat history',
      };
    }
  }
}

