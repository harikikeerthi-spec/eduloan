import { Controller, Post, Body, Get, Param } from '@nestjs/common';
import { EligibilityService } from './services/eligibility.service';
import { LoanRecommendationService } from './services/loan-recommendation.service';
import { SopAnalysisService } from './services/sop-analysis.service';
import { GradeConversionService } from './services/grade-conversion.service';
import { UniversityComparisonService } from './services/university-comparison.service';
import { AdmitPredictorService } from './services/admit-predictor.service';

import { AiSupportService } from './services/ai-support.service';
import { VisaInterviewService } from './services/visa-interview.service';
import { ShortlistingService } from './services/shortlisting.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('ai')
export class AiController {
  constructor(
    private readonly eligibilityService: EligibilityService,
    private readonly loanRecommendationService: LoanRecommendationService,
    private readonly sopAnalysisService: SopAnalysisService,
    private readonly gradeConversionService: GradeConversionService,
    private readonly universityComparisonService: UniversityComparisonService,
    private readonly admitPredictorService: AdmitPredictorService,
    private readonly aiSupportService: AiSupportService,
    private readonly visaInterviewService: VisaInterviewService,
    private readonly shortlistingService: ShortlistingService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('search-countries')
  async searchCountries(@Body() data: { query: string }) {
    const countries = await this.shortlistingService.searchCountries(data.query);
    return { success: true, countries };
  }

  @Post('search-fields')
  async searchFields(@Body() data: { query: string }) {
    const fields = await this.shortlistingService.searchFields(data.query);
    return { success: true, fields };
  }

  @Post('shortlist')
  async shortlist(@Body() data: { profile: any; messages?: any[]; userId?: string }) {
    const result = await this.shortlistingService.shortlist(data.profile, data.messages);

    if (data.userId && result.recommendations) {
      // 1. Save shortlist chat history
      await this.shortlistingService.saveShortlistChat(
        data.userId,
        data.messages || [],
        result.recommendations,
      );

      // 2. Save/Update recommendations in RecommendedUniversity table
      try {
        await this.prisma.recommendedUniversity.deleteMany({
          where: { userId: data.userId },
        });

        await this.prisma.recommendedUniversity.createMany({
          data: result.recommendations.map((uni: any) => ({
            userId: data.userId,
            name: uni.name || '',
            chance: uni.chance ?? null,
            type: uni.type ?? null,
            rank: uni.rank ?? null,
            tuition: uni.tuition ?? null,
            location: uni.location ?? null,
            reason: uni.reason ?? null,
            avgSalary: uni.avgSalary ?? null,
            deadline: uni.deadline ?? null,
            flag: uni.flag ?? null,
            country: uni.country ?? null,
            programName: uni.programName ?? null,
            logoUrl: uni.logoUrl ?? null,
            description: uni.description ?? null,
            roi: uni.roi ?? null,
            acceptanceRate: uni.acceptanceRate ?? null,
            duration: uni.duration ?? null,
            category: uni.category ?? null,
            websiteUrl: uni.websiteUrl ?? null,
          })),
        });
      } catch (dbError) {
        console.error('Failed to save RecommendedUniversity list:', dbError);
      }
    }

    return { success: true, ...result };
  }

  @Post('search-universities')
  async searchUniversities(@Body() data: { query: string; degree: string; country?: string }) {
    const universities = await this.shortlistingService.searchUniversities(data.query, data.degree, data.country);
    return { success: true, universities };
  }

  @Post('search-courses')
  async searchCourses(@Body() data: { university: string; query: string; degree: string }) {
    const courses = await this.shortlistingService.searchCourses(data.university, data.query, data.degree);
    return { success: true, courses };
  }

  @Post('eligibility-check')
  async checkEligibility(
    @Body()
    data: {
      age: number;
      credit: number;
      income: number;
      loan: number;
      employment: 'employed' | 'self' | 'student' | 'unemployed';
      study: 'undergrad' | 'masters' | 'doctoral' | 'diploma';
      maritalStatus: 'single' | 'married';
      coApplicant: 'yes' | 'no';
      collateral: 'yes' | 'no';
    },
  ) {
    // Await the async eligibility check
    const eligibilityResult =
      await this.eligibilityService.calculateEligibilityScore(data);

    // Note: LoanRecommendationService is still synchronous/local logic for now vs LLM,
    // but the controller doesn't need to change for that unless we refactor it too.
    const loanRecommendations = this.loanRecommendationService.recommendLoans(
      eligibilityResult.score,
      data.credit,
      eligibilityResult.ratio,
      data.loan,
      data.coApplicant,
      data.collateral,
      data.study,
    );

    return {
      success: true,
      eligibility: eligibilityResult,
      recommendations: loanRecommendations,
    };
  }

  @Post('sop-analysis')
  async analyzeSop(
    @Body()
    data: {
      sop: string;
    },
  ) {
    console.log('Analyzing SOP:', data.sop?.substring(0, 50) + '...');
    try {
      const result = await this.sopAnalysisService.analyzeSop(data.sop);
      return {
        success: true,
        analysis: result,
      };
    } catch (error) {
      console.error('SOP Analysis Error:', error);
      throw error;
    }
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
    // Construct the input for conversion service
    const result = await this.gradeConversionService.convertGrade({
      inputType: data.percentage ? 'percentage' : 'marks',
      inputValue:
        data.percentage || data.marks?.reduce((a, b) => a + b, 0) || 0,
      totalMarks: data.totalMarks || 100,
      outputType: 'percentage',
      // gradingSystem: 'Standard', // Default (Removed to fix type error)
    });

    // We can reuse the result structure directly or adapt it
    const analysisData = {
      percentage: result.percentage,
      letterGrade: result.letterGrade,
      classification: result.classification,
      internationalEquivalent: result.internationalEquivalent,
      analysis: result.analysis,
      // Pass through marks breakdown if available
      marksBreakdown: data.subjects
        ? data.subjects.map((subject, index) => ({
            subject,
            marks: data.marks?.[index] || 0,
            outOf: (data.totalMarks || 100) / (data.marks?.length || 1),
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
    const result = await this.gradeConversionService.comparePerformance(
      data.assessments,
    );
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
    },
  ) {
    const result = await this.universityComparisonService.compare(
      data.uni1,
      data.uni2,
    );
    return {
      success: true,
      data: result,
    };
  }

  @Post('predict-admission')
  async predictAdmission(
    @Body()
    data: {
      targetUniversity: string;
      gpa: number;
      gpaScale: 4 | 10;
      testScoreType: 'GRE' | 'GMAT' | 'SAT' | 'ACT' | 'None';
      testScore: number;
      englishTestType: 'IELTS' | 'TOEFL' | 'PTE' | 'None';
      englishTestScore: number;
      experienceYears: number;
      researchPapers: number;
      programLevel: 'Undergraduate' | 'Masters' | 'PhD' | 'MBA';
    },
  ) {
    const result = await this.admitPredictorService.predict(data);
    return {
      success: true,
      prediction: result,
    };
  }

  @Post('support-chat')
  async chat(@Body() data: { message: string }) {
    const response = await this.aiSupportService.getResponse(data.message);
    return {
      success: true,
      message: response,
    };
  }

  @Post('visa-interview/start')
  async startVisaInterview(@Body() data: { userProfile: any; visaType: string }) {
    return await this.visaInterviewService.startInterview(
      data.userProfile,
      data.visaType,
    );
  }

  @Post('visa-interview/continue')
  async continueVisaInterview(@Body() data: any) {
    return await this.visaInterviewService.continueInterview(data);
  }

  @Post('visa-interview/evaluate')
  async evaluateVisaAnswer(@Body() data: any) {
    return await this.visaInterviewService.evaluateAnswer(data);
  }

  @Post('visa-interview/final-report')
  async generateVisaReport(@Body() data: any) {
    return await this.visaInterviewService.generateFinalReport(data);
  }

  // Save and retrieve favorite universities and recommendations
  @Post('university/favorite')
  @Post('university/favorites')
  async saveFavorite(
    @Body()
    data: {
      userId: string;
      universityName: string;
      universityData: any;
    },
  ) {
    try {
      const existing = await this.prisma.recommendedUniversity.findFirst({
        where: {
          userId: data.userId,
          name: data.universityName,
          type: 'Saved',
        },
      });

      if (existing) {
        await this.prisma.recommendedUniversity.delete({
          where: { id: existing.id },
        });
        return { success: true, saved: false };
      } else {
        const uni = data.universityData || {};
        await this.prisma.recommendedUniversity.create({
          data: {
            userId: data.userId,
            name: data.universityName,
            chance: uni.chance ?? null,
            type: 'Saved',
            rank: uni.rank ?? null,
            tuition: uni.tuition ?? null,
            location: uni.location ?? null,
            reason: uni.reason ?? null,
            avgSalary: uni.avgSalary ?? null,
            deadline: uni.deadline ?? null,
            flag: uni.flag ?? null,
            country: uni.country ?? null,
            programName: uni.programName ?? null,
            logoUrl: uni.logoUrl ?? null,
            description: uni.description ?? null,
            roi: uni.roi ?? null,
            acceptanceRate: uni.acceptanceRate ?? null,
            duration: uni.duration ?? null,
            category: uni.category ?? null,
            websiteUrl: uni.websiteUrl ?? null,
          },
        });
        return { success: true, saved: true };
      }
    } catch (error) {
      console.error('Failed to toggle favorite university:', error);
      return { success: false, error: error.message };
    }
  }

  @Post('recommendations')
  async saveRecommendation() {
    return { success: true };
  }

  @Get('university/favorites/:userId')
  async getFavorites(@Param('userId') userId: string) {
    try {
      const favorites = await this.prisma.recommendedUniversity.findMany({
        where: {
          userId,
          type: 'Saved',
        },
        orderBy: { createdAt: 'desc' },
      });

      const formatted = favorites.map((uni) => ({
        universityData: {
          name: uni.name,
          chance: uni.chance,
          type: uni.type,
          rank: uni.rank,
          tuition: uni.tuition,
          location: uni.location,
          reason: uni.reason,
          avgSalary: uni.avgSalary,
          deadline: uni.deadline,
          flag: uni.flag,
          country: uni.country,
          programName: uni.programName,
          logoUrl: uni.logoUrl,
          description: uni.description,
          roi: uni.roi,
          acceptanceRate: uni.acceptanceRate,
          duration: uni.duration,
          category: uni.category,
          websiteUrl: uni.websiteUrl,
        },
      }));

      return formatted;
    } catch (error) {
      console.error('Failed to get favorites:', error);
      return [];
    }
  }

  @Get('recommendations/:userId')
  async getRecommendations(@Param('userId') userId: string) {
    try {
      const recommendations = await this.prisma.recommendedUniversity.findMany({
        where: {
          userId,
          NOT: {
            type: 'Saved',
          },
        },
        orderBy: { createdAt: 'desc' },
      });
      return { success: true, recommendations };
    } catch (error) {
      console.error('Failed to get recommendations:', error);
      return { success: false, recommendations: [] };
    }
  }

  @Get('shortlist/:userId')
  async getLatestShortlistChat(@Param('userId') userId: string) {
    try {
      const chat = await this.shortlistingService.getLatestShortlistChat(userId);
      return { success: true, chat };
    } catch (error) {
      console.error('Failed to get shortlist chat:', error);
      return { success: false, error: error.message };
    }
  }

}
