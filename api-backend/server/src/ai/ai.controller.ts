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

  @Post('loan-recommendations')
  async getLoanRecommendations(
    @Body()
    profile: any,
  ) {
    const result = await this.loanRecommendationService.recommendChatLoans(profile);
    return {
      success: true,
      data: result,
      ...result,
    };
  }

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
    const result = await this.admitPredictorService.predict(body);
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
        const universities = await this.universitySearchService.searchUniversitiesByCountry([country], 12);
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
    data: {
      countries?: string[];
      limit?: number;
      query?: string;
      degree?: string;
      country?: string;
    },
  ) {
    try {
      const allowIndia = (data.country || '').toLowerCase() === 'india' || 
                         (data.countries || []).some(c => c.toLowerCase() === 'india');

      if (data.query !== undefined || data.country !== undefined) {
        const query = data.query || '';
        const country = data.country || '';
        const degree = data.degree || 'masters';

        // Check Supabase first
        try {
          const db = this.supabase.getClient();
          let dbQuery = db.from('University').select('*');
          if (country) {
            dbQuery = dbQuery.ilike('country', `%${country}%`);
          }
          if (query) {
            dbQuery = dbQuery.ilike('name', `%${query}%`);
          }
          const { data: dbUnis } = await dbQuery.limit(15);
          if (dbUnis && dbUnis.length > 0) {
            const formatted = dbUnis
              .filter(u => {
                if (allowIndia) return true;
                const c = (u.country || '').toLowerCase();
                return c !== 'india' && c !== 'in';
              })
              .map(u => ({
                name: String(u.name || ''),
                location: String(u.loc || (u.city || u.country ? `${u.city || ''}, ${u.country || ''}` : 'N/A')),
                city: String(u.city || ''),
                country: String(u.country || ''),
                rank: String(u.ranking || u.worldRanking || 'N/A'),
                tuition: String(u.tuition || u.averageFees || 'N/A'),
                rate: String(u.accept || u.acceptanceRate || 'N/A'),
                salary: String(u.averageSalary || 'N/A'),
                slug: String(u.slug || (u.name ? u.name.toLowerCase().replace(/[^a-z0-9]+/g, '-') : ''))
              }));
            return {
              success: true,
              universities: formatted
            };
          }
        } catch (e) {
          console.error('Failed to search universities in DB', e);
        }

        // Fallback: AI Search via OpenRouter
        const prompt = allowIndia
          ? `Search for REAL, ACCREDITED colleges, undergraduate degree institutions, or universities located in India, matching or relevant to "${query}".
          
          Return a JSON object with a "universities" key.
          The "universities" key should be an array of up to 12 objects.
          For each university, provide:
          - name (string)
          - location (string, format "City, State, India")
          - city (string)
          - country (string, must be "India")
          - rank (string/number, local or world rank)
          - accept (string/number, acceptance rate or N/A)
          - tuition (string/number, tuition fees in INR/USD or N/A)
          - avgSalary (string/number, average placement package or N/A)
          - slug (string)
          
          MUST respond ONLY with JSON.`
          : `Search for REAL, ACCREDITED universities ${query ? `matching or relevant to "${query}"` : 'that are popular'} for international students.
          ${country ? `Focus primarily on universities located in "${country}".` : ''}
          CRITICAL: Do NOT include any universities located in India. This is strictly for study abroad.
          
          Return a JSON object with a "universities" key.
          The "universities" key should be an array of up to 12 objects.
          For each university, provide:
          - name (string)
          - location (string, format "City, Country" or "City, State, Country")
          - city (string)
          - country (string)
          - rank (string/number)
          - accept (string/number)
          - tuition (string/number)
          - avgSalary (string/number)
          - slug (string)
          
          MUST respond ONLY with JSON.`;

        const aiRes = await this.openRouterService.getJson<any>(prompt);
        const list = aiRes?.universities || [];
        
        const formatted = list
          .filter((u: any) => {
            if (!u) return false;
            if (allowIndia) return true;
            const cStr = (u.country || country || '').toLowerCase();
            const locStr = (u.location || u.loc || '').toLowerCase();
            return cStr !== 'india' && cStr !== 'in' && locStr.indexOf('india') === -1;
          })
          .map((u: any) => ({
            name: String(u.name || ''),
            location: String(u.location || u.loc || (u.city || u.country ? `${u.city || ''}, ${u.country || ''}` : 'N/A')),
            city: String(u.city || ''),
            country: String(u.country || country || ''),
            rank: String(u.rank || u.ranking || 'N/A'),
            tuition: String(u.tuition || u.averageFees || 'N/A'),
            rate: String(u.accept || u.acceptanceRate || 'N/A'),
            salary: String(u.avgSalary || u.averageSalary || 'N/A'),
            slug: String(u.slug || (u.name ? u.name.toLowerCase().replace(/[^a-z0-9]+/g, '-') : ''))
          }));

        return {
          success: true,
          universities: formatted
        };
      }

      // Existing schema
      if (!data.countries || data.countries.length === 0) {
        throw new BadRequestException('At least one country is required');
      }

      const universities = await this.universitySearchService.searchUniversitiesByCountry(
        data.countries,
        data.limit || 10,
      );

      const validUniversities = await this.universitySearchService.validateUniversityRealness(universities);

      const filteredUnis = validUniversities
        .filter(u => {
          if (allowIndia) return true;
          return (u.country || '').toLowerCase() !== 'india';
        })
        .map((u: any) => ({
          name: String(u.name || ''),
          location: String(u.loc || (u.city || u.country ? `${u.city || ''}, ${u.country || ''}` : 'N/A')),
          city: String(u.city || ''),
          country: String(u.country || ''),
          rank: String(u.rank || u.ranking || u.worldRanking || 'N/A'),
          tuition: String(u.tuition || u.averageFees || 'N/A'),
          rate: String(u.accept || u.acceptanceRate || 'N/A'),
          salary: 'N/A',
          slug: String(u.slug || (u.name ? u.name.toLowerCase().replace(/[^a-z0-9]+/g, '-') : ''))
        }));

      return {
        success: true,
        universities: filteredUnis,
        totalCount: filteredUnis.length,
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
        countries: countries.filter(c => c.toLowerCase() !== 'india'),
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

  @Post('search-countries')
  async searchCountries(@Body() body: { query?: string }) {
    const getCountryFlag = (name: string, fallbackFlag?: string): string => {
      const flags: Record<string, string> = {
        'united states': '🇺🇸',
        'united states of america': '🇺🇸',
        'usa': '🇺🇸',
        'united kingdom': '🇬🇧',
        'uk': '🇬🇧',
        'canada': '🇨🇦',
        'australia': '🇦🇺',
        'germany': '🇩🇪',
        'france': '🇫🇷',
        'singapore': '🇸🇬',
        'ireland': '🇮🇪',
        'new zealand': '🇳🇿',
        'netherlands': '🇳🇱',
        'switzerland': '🇨🇭',
        'sweden': '🇸🇪',
        'spain': '🇪🇸',
        'italy': '🇮🇹',
        'india': '🇮🇳'
      };
      const key = name.trim().toLowerCase();
      return flags[key] || fallbackFlag || '🌐';
    };

    const query = body.query || '';
    try {
      const db = this.supabase.getClient();
      let res;
      if (query.trim()) {
        res = await db.from('Country').select('*').ilike('name', `%${query}%`).neq('name', 'India').limit(15);
      } else {
        res = await db.from('Country').select('*').eq('popularForStudy', true).neq('name', 'India').order('name', { ascending: true });
      }
      if (res.data && res.data.length > 0) {
        return {
          success: true,
          countries: res.data
            .filter(c => (c.name || '').toLowerCase() !== 'india')
            .map(c => ({
              name: String(c.name || ''),
              code: String(c.code || ''),
              flag: getCountryFlag(c.name, c.flag || '')
            }))
        };
      }
    } catch (e) {
      console.error('Failed to query countries from DB, falling back to static/AI', e);
    }

    const popularCountries = [
      { name: 'United States', code: 'US', flag: '🇺🇸' },
      { name: 'United Kingdom', code: 'GB', flag: '🇬🇧' },
      { name: 'Canada', code: 'CA', flag: '🇨🇦' },
      { name: 'Australia', code: 'AU', flag: '🇦🇺' },
      { name: 'Germany', code: 'DE', flag: '🇩🇪' },
      { name: 'France', code: 'FR', flag: '🇫🇷' },
      { name: 'Singapore', code: 'SG', flag: '🇸🇬' },
      { name: 'Ireland', code: 'IE', flag: '🇮🇪' },
      { name: 'New Zealand', code: 'NZ', flag: '🇳🇿' },
      { name: 'Netherlands', code: 'NL', flag: '🇳🇱' },
      { name: 'Switzerland', code: 'CH', flag: '🇨🇭' },
      { name: 'Sweden', code: 'SE', flag: '🇸🇪' },
      { name: 'Spain', code: 'ES', flag: '🇪🇸' },
      { name: 'Italy', code: 'IT', flag: '🇮🇹' }
    ];

    let filtered = popularCountries;
    if (query.trim()) {
      const lower = query.toLowerCase();
      filtered = popularCountries.filter(
        c => c.name.toLowerCase().includes(lower) && c.name.toLowerCase() !== 'india'
      );
      
      if (filtered.length === 0) {
        try {
          const prompt = `List up to 5 real countries that match or are closely related to the query "${query}". Return a JSON object with a "countries" key. Each country must have "name", "code" (uppercase 2 letter country code), and "flag" (the flag emoji). E.g. {"countries": [{"name": "Germany", "code": "DE", "flag": "🇩🇪"}]}. CRITICAL: Do NOT include India under any circumstances.`;
          const aiRes = await this.openRouterService.getJson<any>(prompt);
          if (aiRes && aiRes.countries) {
            const normalized = aiRes.countries
              .filter((c: any) => (c.name || '').toLowerCase() !== 'india' && (c.code || '').toLowerCase() !== 'in')
              .map((c: any) => ({
                name: String(c.name || ''),
                code: String(c.code || ''),
                flag: getCountryFlag(c.name, c.flag || '')
              }));
            return { success: true, countries: normalized };
          }
        } catch (e) {
          console.error('AI country search failed', e);
        }
      }
    }

    return {
      success: true,
      countries: filtered
    };
  }

  @Post('search-fields')
  async searchFields(@Body() body: { query?: string }) {
    const query = body.query || '';
    try {
      const db = this.supabase.getClient();
      const { data } = await db.from('Course').select('field');
      if (data && data.length > 0) {
        const uniqueFields = Array.from(new Set(data.map(item => item.field).filter(Boolean))) as string[];
        let filtered = uniqueFields;
        if (query.trim()) {
          const lower = query.toLowerCase();
          filtered = uniqueFields.filter(f => f.toLowerCase().includes(lower));
        }
        return {
          success: true,
          fields: filtered.slice(0, 15)
        };
      }
    } catch (e) {
      console.error('Failed to query unique fields from DB', e);
    }

    const defaultFields = [
      'Computer Science',
      'Data Science',
      'Information Technology',
      'Business Administration',
      'Finance',
      'Mechanical Engineering',
      'Electrical Engineering',
      'Civil Engineering',
      'Biotechnology',
      'Medicine',
      'Public Health',
      'Data Analytics',
      'Artificial Intelligence',
      'Cybersecurity'
    ];

    let filtered = defaultFields;
    if (query.trim()) {
      const lower = query.toLowerCase();
      filtered = defaultFields.filter(f => f.toLowerCase().includes(lower));
      
      if (filtered.length === 0) {
        try {
          const prompt = `List up to 8 real academic fields of study (e.g. Computer Science, Mechanical Engineering) matching or related to the query "${query}". Return a JSON object with a "fields" key. E.g. {"fields": ["Computer Science", "Artificial Intelligence"]}`;
          const aiRes = await this.openRouterService.getJson<any>(prompt);
          if (aiRes && aiRes.fields) {
            return { success: true, fields: aiRes.fields };
          }
        } catch (e) {
          console.error('AI fields search failed', e);
        }
      }
    }

    return {
      success: true,
      fields: filtered
    };
  }

  @Post('search-courses')
  async searchCourses(@Body() body: { university?: string; query?: string; degree?: string }) {
    const university = body.university || '';
    const query = body.query || '';
    const degree = body.degree || 'masters';

    try {
      const prompt = `List up to 10 real academic courses or programs (e.g. Master of Science in Computer Science, MBA) offered at the university "${university}" ${query ? `matching or relevant to "${query}"` : ''} for a ${degree} degree.
      
      Return a JSON object with a "courses" key. The value should be an array of objects, each with a "name" key.
      E.g.
      {
        "courses": [
          { "name": "M.S. in Computer Science" },
          { "name": "Master of Business Administration (MBA)" }
        ]
      }
      
      MUST respond ONLY with JSON.`;

      const aiRes = await this.openRouterService.getJson<any>(prompt);
      if (aiRes && aiRes.courses) {
        const formatted = (Array.isArray(aiRes.courses) ? aiRes.courses : [])
          .filter((c: any) => c && typeof c === 'object')
          .map((c: any) => ({
            name: String(c.name || '')
          }));
        return { success: true, courses: formatted };
      }
    } catch (e) {
      console.error('AI course search failed, falling back', e);
    }

    const defaultCourses = [
      { name: `M.S. in Computer Science` },
      { name: `M.S. in Data Science` },
      { name: `Master of Business Administration (MBA)` },
      { name: `M.S. in Mechanical Engineering` },
      { name: `M.S. in Electrical Engineering` },
      { name: `M.S. in Business Analytics` },
      { name: `M.S. in Information Systems` }
    ];
    return {
      success: true,
      courses: defaultCourses
    };
  }

  // ── Visa Interview Simulator Endpoints ──

  @Post('shortlist')
  async shortlistUniversities(
    @Body() data: { profile: Record<string, any>; userId?: string; messages?: any[] },
  ) {
    try {
      const profile = data.profile || {};
      const degree = profile.degree || "Master's";
      const country = profile.country || 'USA';
      const major = profile.major || 'Computer Science';
      const gpa = profile.gpa || '8.0';
      const backlogs = profile.backlogs || 'No';
      const tests = profile.tests || 'Not taken';
      const experience = profile.experience || 'Fresher';
      const selectedUniversities = profile.selectedUniversities as Array<{ name: string; course: string }> | null;
      const isEvaluate = selectedUniversities && selectedUniversities.length > 0;

      let prompt: string;
      if (isEvaluate) {
        const uniList = selectedUniversities.map((u, i) => `${i + 1}. ${u.name} (Program: ${u.course})`).join('\n');
        prompt = `You are an expert university counselor. Evaluate the following shortlisted universities for an Indian student applying for ${degree} programs.

Student Profile:
- Current Degree/Background: ${profile.bachelorCourse || 'Engineering'}
- GPA/CGPA: ${gpa}
- Backlogs: ${backlogs}
- Test Scores: ${tests}
- Work Experience: ${experience}

Shortlisted Universities:
${uniList}

For each university, provide:
1. Admission chance (High / Medium / Low)
2. Category (Safe / Moderate / Ambitious)
3. Key reason for the assessment
4. Estimated tuition (annual, in USD)
5. World rank
6. Location
7. Average salary post-graduation (USD)
8. Acceptance rate (%)
9. Application deadline (typical)
10. Flag emoji for the country
11. Country name
12. Program name (as provided)
13. University website domain (e.g. mit.edu)
14. Brief description (1-2 sentences)
15. ROI (e.g. "High – 80% placement")
16. Duration (e.g. "2 years")
17. Indian student community size (Small/Medium/Large)
18. Cost of living (e.g. "$1200-1800/month")
19. University type (Public/Private)

Return ONLY a JSON object like:
{
  "recommendations": [
    {
      "name": "...",
      "chance": "High|Medium|Low",
      "type": "Safe|Moderate|Ambitious",
      "rank": "...",
      "tuition": "...",
      "location": "...",
      "reason": "...",
      "avgSalary": "...",
      "deadline": "...",
      "flag": "...",
      "country": "...",
      "programName": "...",
      "websiteUrl": "...",
      "description": "...",
      "roi": "...",
      "acceptanceRate": "...",
      "duration": "...",
      "indianCommunity": "...",
      "costOfLiving": "...",
      "universityType": "..."
    }
  ]
}`;
      } else {
        prompt = `You are an expert university counselor specializing in international admissions. Recommend the best ${degree} universities in ${country} for an Indian student.

Student Profile:
- Target Degree: ${degree}
- Target Country: ${country}
- Field of Study: ${major}
- Bachelor's Background: ${profile.bachelorCourse || 'Engineering'}
- GPA/CGPA: ${gpa} / 10
- Backlogs: ${backlogs}
- Test Scores: ${tests}
- Work Experience: ${experience}

Recommend exactly 8 universities split across 3 tiers: 3 Safe, 3 Moderate (Target), 2 Ambitious.

For each university, provide:
1. University name (real, accredited)
2. Admission chance (High / Medium / Low)
3. Category (Safe / Moderate / Ambitious)
4. World ranking
5. Annual tuition in USD
6. Location (City, Country)
7. Key reason why it suits this student
8. Average post-graduation salary (USD)
9. Typical application deadline
10. Country flag emoji
11. Country name
12. Recommended program name
13. University website domain
14. Brief description (1-2 sentences)
15. ROI assessment
16. Acceptance rate (%)
17. Program duration (e.g. "2 years")
18. Indian student community (Small/Medium/Large)
19. Cost of living per month (USD)
20. University type (Public/Private)

Return ONLY valid JSON:
{
  "recommendations": [
    {
      "name": "...",
      "chance": "High|Medium|Low",
      "type": "Safe|Moderate|Ambitious",
      "rank": "...",
      "tuition": "...",
      "location": "...",
      "reason": "...",
      "avgSalary": "...",
      "deadline": "...",
      "flag": "...",
      "country": "...",
      "programName": "...",
      "websiteUrl": "...",
      "description": "...",
      "roi": "...",
      "acceptanceRate": "...",
      "duration": "...",
      "indianCommunity": "...",
      "costOfLiving": "...",
      "universityType": "..."
    }
  ]
}`;
      }

      const result = await this.openRouterService.getJson<{ recommendations: any[] }>(prompt);
      const recommendations = result?.recommendations || [];

      // Persist to Supabase if userId provided
      if (data.userId && recommendations.length > 0) {
        try {
          await this.supabase.getClient()
            .from('ShortlistChat')
            .upsert({
              userId: data.userId,
              recommendations,
              messages: data.messages || [],
              updatedAt: new Date().toISOString(),
            }, { onConflict: 'userId' });
        } catch (e) {
          console.warn('Failed to save shortlist chat to DB (non-fatal):', e);
        }
      }

      return {
        success: true,
        recommendations,
        data: { recommendations },
      };
    } catch (error) {
      console.error('Shortlist generation failed:', error);
      throw error;
    }
  }

  @Get('shortlist/:userId')
  async getLatestShortlistChat(@Param('userId') userId: string) {
    try {
      const { data, error } = await this.supabase.getClient()
        .from('ShortlistChat')
        .select('*')
        .eq('userId', userId)
        .order('updatedAt', { ascending: false })
        .limit(1)
        .single();

      if (error || !data) {
        return { success: false, chat: null };
      }

      return {
        success: true,
        chat: {
          recommendations: data.recommendations || [],
          messages: data.messages || [],
        },
      };
    } catch (e) {
      console.warn('Failed to load shortlist from DB:', e);
      return { success: false, chat: null };
    }
  }

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

  @Get('university/favorites/:userId')
  async getSavedUniversities(@Param('userId') userId: string) {
    try {
      const { data, error } = await this.supabase.getClient()
        .from('RecommendedUniversity')
        .select('*')
        .eq('userId', userId);

      if (error) throw error;

      const formatted = (data || []).map(item => ({
        id: item.id,
        userId: item.userId,
        universityName: item.name,
        universityData: {
          name: item.name,
          chance: item.chance,
          type: item.type,
          rank: item.rank,
          tuition: item.tuition,
          location: item.location,
          reason: item.reason,
          avgSalary: item.avgSalary,
          deadline: item.deadline,
          flag: item.flag,
          country: item.country,
          programName: item.programName,
          logoUrl: item.logoUrl,
          description: item.description,
          roi: item.roi,
          acceptanceRate: item.acceptanceRate,
          duration: item.duration,
          category: item.category,
          websiteUrl: item.websiteUrl,
        }
      }));

      return formatted;
    } catch (e) {
      console.warn('Failed to fetch saved universities:', e);
      return [];
    }
  }

  @Post('university/favorite')
  async toggleSaveUniversity(
    @Body() data: { userId: string; universityName: string; universityData: Record<string, any> }
  ) {
    try {
      const db = this.supabase.getClient();
      
      const { data: existing, error: fetchError } = await db
        .from('RecommendedUniversity')
        .select('id')
        .eq('userId', data.userId)
        .eq('name', data.universityName)
        .maybeSingle();

      if (fetchError) throw fetchError;

      if (existing) {
        const { error: deleteError } = await db
          .from('RecommendedUniversity')
          .delete()
          .eq('id', existing.id);
        
        if (deleteError) throw deleteError;
        
        return { success: true, saved: false };
      } else {
        const uData = data.universityData || {};
        const { error: insertError } = await db
          .from('RecommendedUniversity')
          .insert({
            userId: data.userId,
            name: data.universityName,
            chance: String(uData.chance || ''),
            type: String(uData.type || ''),
            rank: String(uData.rank || ''),
            tuition: String(uData.tuition || ''),
            location: String(uData.location || ''),
            reason: String(uData.reason || ''),
            avgSalary: String(uData.avgSalary || uData.averageSalary || ''),
            deadline: String(uData.deadline || ''),
            flag: String(uData.flag || ''),
            country: String(uData.country || ''),
            programName: String(uData.programName || ''),
            logoUrl: String(uData.logoUrl || ''),
            description: String(uData.description || ''),
            roi: String(uData.roi || ''),
            acceptanceRate: String(uData.acceptanceRate || ''),
            duration: String(uData.duration || ''),
            category: String(uData.category || ''),
            websiteUrl: String(uData.websiteUrl || ''),
          });

        if (insertError) throw insertError;
        
        return { success: true, saved: true };
      }
    } catch (e) {
      console.error('Failed to toggle favorite university:', e);
      return { success: false, saved: false, message: e.message || 'Failed' };
    }
  }

  @Post('pincode-lookup')
  async lookupPincode(@Body() body: { pincode: string }) {
    const pincode = body.pincode;
    if (!pincode || pincode.length !== 6) {
      throw new BadRequestException('A valid 6-digit pincode is required');
    }

    const prompt = `Given the Indian pincode "${pincode}", identify the corresponding city and state.
    
    Respond with strictly valid JSON:
    {
       "address": "City, State"
    }`;

    try {
      const result = await this.openRouterService.getJson<{ address: string }>(prompt);
      return {
        success: true,
        address: result.address || 'Unknown Location',
      };
    } catch (error) {
      console.error('Pincode lookup failed:', error);
      return {
        success: false,
        address: 'Unknown Location',
      };
    }
  }

  @Post('university/view')
  async trackUniversityView(@Body() data: any) {
    return { success: true };
  }
}

