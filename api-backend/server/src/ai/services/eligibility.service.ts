import { Injectable } from '@nestjs/common';
import { OpenRouterService } from './openrouter.service';
import { SupabaseService } from '../../supabase/supabase.service';

export interface EligibilityCheckDto {
  age: number;
  credit: number;
  income: number;
  loan: number;
  employment: 'employed' | 'self' | 'student' | 'unemployed';
  study: 'undergrad' | 'masters' | 'doctoral' | 'diploma';
  coApplicant: 'yes' | 'no';
  collateral: 'yes' | 'no';
}

export interface EligibilityResult {
  score: number;
  status: 'eligible' | 'borderline' | 'unlikely';
  ratio: number;
  rateRange: string;
  coverage: string;
  summary: string;
  recommendations: string[];
}

@Injectable()
export class EligibilityService {
  constructor(
    private readonly openRouter: OpenRouterService,
    private readonly supabase: SupabaseService,
  ) {}

  async calculateEligibilityScore(data: EligibilityCheckDto): Promise<EligibilityResult> {
    // Strict rule: CIBIL / Credit score below 700 is NOT eligible
    if (data.credit < 700) {
      return {
        score: Math.max(15, Math.round((data.credit / 700) * 40)),
        status: 'unlikely',
        ratio: data.income > 0 ? Number((data.loan / data.income).toFixed(2)) : 0,
        rateRange: 'N/A',
        coverage: '0%',
        summary: `CIBIL score below 700 (${data.credit}) is not eligible for loan approval. A minimum CIBIL score of 700 is required by financial institutions.`,
        recommendations: [
          'Improve your CIBIL score to 700+ by clearing active credit dues',
          'Add a financial co-applicant with a CIBIL score of 750+',
          'Provide high-value collateral to offset credit score deficit'
        ],
      };
    }

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
    2. Determine status (eligible, borderline, unlikely). Note: Credit score below 700 is NOT eligible.
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
    `;

    try {
      return await this.openRouter.getJson<EligibilityResult>(prompt);
    } catch (error) {
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

  async saveLog(data: any): Promise<void> {
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
    } catch (e) {
      console.error('Failed to save eligibility log:', e);
    }
  }
}

