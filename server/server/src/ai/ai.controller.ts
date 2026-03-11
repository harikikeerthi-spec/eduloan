import { Controller, Post, Get, Body, Param, BadRequestException, Logger } from '@nestjs/common';
import { EligibilityService } from './services/eligibility.service';
import { LoanRecommendationService } from './services/loan-recommendation.service';
import { SopAnalysisService } from './services/sop-analysis.service';
import { GradeConversionService } from './services/grade-conversion.service';
import { UniversityComparisonService } from './services/university-comparison.service';
import { AdmitPredictorService } from './services/admit-predictor.service';
import { UniversityShortlistService } from './services/university-shortlist.service';
import { VisaInterviewService, InterviewMessage, EvaluationResult } from './services/visa-interview.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('ai')
export class AiController {
  private readonly logger = new Logger(AiController.name);

  constructor(
    private readonly eligibilityService: EligibilityService,
    private readonly loanRecommendationService: LoanRecommendationService,
    private readonly sopAnalysisService: SopAnalysisService,
    private readonly gradeConversionService: GradeConversionService,
    private readonly universityComparisonService: UniversityComparisonService,
    private readonly admitPredictorService: AdmitPredictorService,
    private readonly universityShortlistService: UniversityShortlistService,
    private readonly visaInterviewService: VisaInterviewService,
    private readonly prisma: PrismaService,
  ) { }

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
      coApplicant: 'yes' | 'no';
      collateral: 'yes' | 'no';
      userId?: string;
    },
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
    
    // Save Usage
    try {
      await this.prisma.aiEligibilityCheck.create({
        data: {
          userId: data.userId || null,
          profileData: { age: data.age, credit: data.credit, income: data.income, loan: data.loan, employment: data.employment, study: data.study, coApplicant: data.coApplicant, collateral: data.collateral },
          eligibilityScore: eligibilityResult.score,
          eligibilityRatio: eligibilityResult.ratio,
        }
      });
      await this.prisma.aiLoanRecommendation.create({
        data: {
          userId: data.userId || null,
          eligibilityScore: eligibilityResult.score,
          requestedAmount: data.loan,
          recommendations: loanRecommendations as any,
        }
      });
    } catch (e) {
      this.logger.error(`Failed to save AI Tracking: ${e.message}`);
    }

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
      text?: string;
      sop?: string;
      userId?: string;
    },
  ) {
    const sopText = data.text || data.sop || '';
    const result = await this.sopAnalysisService.analyzeSop(sopText);
    
    try {
      await this.prisma.aiSopAnalysis.create({
        data: {
          userId: data.userId || null,
          originalText: sopText,
          analysisResult: result as any,
        }
      });
    } catch (e) {
      this.logger.error(`Failed to save SOP Tracking: ${e.message}`);
    }
    
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
      userId?: string;
    },
  ) {
    const result = await this.sopAnalysisService.humanizeSop(data.text);
    
    try {
      await this.prisma.aiSopAnalysis.create({
        data: {
          userId: data.userId || null,
          originalText: data.text,
          humanizedText: result.humanizedText,
        }
      });
    } catch (e) {
      this.logger.error(`Failed to save Humanize SOP Tracking: ${e.message}`);
    }

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
      userId?: string;
    },
  ): Promise<any> {
    const result = await this.gradeConversionService.convertGrade(data);
    
    try {
      await this.prisma.aiGradeConversion.create({
        data: {
          userId: data.userId || null,
          inputType: data.inputType,
          inputValue: data.inputValue.toString(),
          outputType: data.outputType,
          gradingSystem: data.gradingSystem,
          conversionResult: result as any,
        }
      });
    } catch (e) {
      this.logger.error(`Failed to save Grade Conv Tracking: ${e.message}`);
    }
    
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
      userId?: string;
    },
  ) {
    const result = await this.universityComparisonService.compare(
      data.uni1,
      data.uni2,
      data.program1,
      data.program2
    );
    
    try {
      await this.prisma.aiUniversityComparison.create({
        data: {
          userId: data.userId || null,
          university1: data.uni1,
          university2: data.uni2,
          program1: data.program1,
          program2: data.program2,
          comparisonResult: result as any,
        }
      });
    } catch (e) {
      this.logger.error(`Failed to save Uni Compare Tracking: ${e.message}`);
    }

    return {
      success: true,
      data: result,
    };
  }

  @Post('predict-admission')
  async predictAdmission(@Body() body: any) {
    const userId = body.userId;
    delete body.userId; // Optionally remove so it doesn't interfere, or keep it.
    
    const result = await this.admitPredictorService.predict(body);
    
    try {
      await this.prisma.aiAdmitPrediction.create({
        data: {
          userId: userId || null,
          profileData: body,
          predictions: result as any,
        }
      });
    } catch (e) {
      this.logger.error(`Failed to save Admit Predict Tracking: ${e.message}`);
    }

    return {
      success: true,
      prediction: result
    };
  }

  @Post('search-countries')
  async searchCountries(@Body('query') query: string) {
    this.logger.log(`Received search-countries request with query: ${query}`);
    return this.universityShortlistService.searchCountries(query || '');
  }

  @Post('search-universities')
  async searchUniversities(
    @Body() data: { query: string; degree?: string; country?: string },
  ) {
    return this.universityShortlistService.searchUniversities(
      data.query || '',
      data.degree,
      data.country,
    );
  }

  @Post('search-courses')
  async searchCourses(
    @Body() data: { university: string; query: string; degree: string },
  ) {
    return this.universityShortlistService.searchCourses(
      data.university,
      data.query || '',
      data.degree,
    );
  }

  @Post('search-fields')
  async searchFields(@Body('query') query: string) {
    return this.universityShortlistService.searchFields(query || '');
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
    const profile = data.profile || data; // Handle both direct profile and wrapped data
    const result = await this.universityShortlistService.shortlist(profile);

    // If userId is provided, save the chat history
    if (data.userId && result.success) {
      // We don't await this to keep the response fast, or we can await it if we want to ensure it's saved.
      // Given the user's request, let's just trigger it.
      this.universityShortlistService.saveChat(
        data.userId,
        profile,
        data.messages || [],
        result.recommendations || [],
      ).catch(err => this.logger.error(`Failed to save shortlist chat: ${err.message}`));
    }

    return result;
  }

  @Post('university/favorite')
  async toggleFavorite(
    @Body() data: { userId: string; universityName: string; universityData: any },
  ) {
    return this.universityShortlistService.toggleFavorite(
      data.userId,
      data.universityName,
      data.universityData,
    );
  }

  @Get('university/favorites/:userId')
  async getFavorites(@Param('userId') userId: string) {
    return this.universityShortlistService.getFavorites(userId);
  }

  @Post('university/view')
  async trackView(
    @Body() data: { userId?: string; universityName: string; programName?: string; location?: string },
  ) {
    return this.universityShortlistService.trackView(
      data.userId || null,
      data.universityName,
      data.programName,
      data.location,
    );
  }

  // ── Visa Interview Simulator Endpoints ──

  @Post('visa-interview/start')
  async startVisaInterview(
    @Body() data: { userProfile: Record<string, any>; visaType?: string },
  ) {
    try {
      const result = await this.visaInterviewService.startInterview(
        data.userProfile || {},
        data.visaType || 'F1 Student Visa',
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
      userId?: string;
      studentProfile?: Record<string, any>;
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
      
      try {
        await this.prisma.aiVisaInterview.create({
          data: {
            userId: data.userId || null,
            visaType: data.visaType || 'F1 Student Visa',
            studentProfile: data.studentProfile || {},
            transcript: data.conversationHistory as any,
            finalScore: report.overallScore,
            evaluation: report as any,
          }
        });
      } catch (e) {
        this.logger.error(`Failed to save Visa Interview Tracking: ${e.message}`);
      }

      return { success: true, report };
    } catch (error) {
      console.error('Final report generation failed:', error);
      return { success: false, message: error.message || 'Failed to generate report' };
    }
  }
}

