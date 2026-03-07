import { Controller, Post, Body, BadRequestException, Logger } from '@nestjs/common';
import { EligibilityService } from './services/eligibility.service';
import { LoanRecommendationService } from './services/loan-recommendation.service';
import { SopAnalysisService } from './services/sop-analysis.service';
import { GradeConversionService } from './services/grade-conversion.service';
import { UniversityComparisonService } from './services/university-comparison.service';
import { AdmitPredictorService } from './services/admit-predictor.service';
import { UniversityShortlistService } from './services/university-shortlist.service';

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

  @Post('predict-admission')
  async predictAdmission(@Body() body: any) {
    const result = await this.admitPredictorService.predict(body);
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
  async shortlist(@Body() profile: any) {
    return this.universityShortlistService.shortlist(profile);
  }
}

