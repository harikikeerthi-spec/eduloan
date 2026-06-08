import { Injectable } from '@nestjs/common';
import { OpenRouterService } from './openrouter.service';

export interface LoanOffer {
  id: string;
  bank: string;
  name: string;
  minScore: number;
  minCredit: number;
  minRatio: number;
  maxLoan: number;
  requiresCoApplicant: boolean;
  requiresCollateral: boolean;
  apr: string;
  coverage: string;
  bestFor: string;
}

export interface LoanRecommendationResult {
  primary: { offer: LoanOffer; fit: number };
  alternatives: Array<{ offer: LoanOffer; fit: number }>;
}

@Injectable()
export class LoanRecommendationService {
  constructor(private readonly openRouter: OpenRouterService) { }

  async recommendLoans(
    score: number,
    credit: number,
    ratio: number,
    loan: number,
    coApplicant: 'yes' | 'no',
    collateral: 'yes' | 'no',
    study: string,
  ): Promise<LoanRecommendationResult> {
    const profile = `
      Validation Score: ${score}
      Credit Score: ${credit}
      Income Ratio: ${ratio}
      Loan Amount: ${loan} (in INR)
      Co-Applicant: ${coApplicant}
      Collateral: ${collateral}
      Study Level: ${study}
    `;

    const prompt = `
    Based on the following student loan applicant profile, GENERATE 3 realistic and competitive loan offers.
    Do not use a predefined list. Create offers that would be suitable from major banks or fintech lenders.

    Applicant Profile:
    ${profile}

    Task:
    1. Generate a "Primary" loan offer that is the best fit.
    2. Generate 2 "Alternative" offers with slightly different terms (e.g. lower rate but requires collateral, or flexibility but higher rate).
    3. Calculate a "fit" score (0-100) for each.

    Return JSON format:
    {
      "primary": { 
        "offer": {
          "id": "generated-id-1",
          "bank": "Bank Name",
          "name": "Loan Product Name",
          "minScore": number,
          "minCredit": number,
          "minRatio": number,
          "maxLoan": number,
          "requiresCoApplicant": boolean,
          "requiresCollateral": boolean,
          "apr": "string range (e.g. 9.5% - 11.0%)",
          "coverage": "string (e.g. Up to 100%)",
          "bestFor": "string reason"
        }, 
        "fit": number 
      },
      "alternatives": [
        { "offer": { ...same structure... }, "fit": number }
      ]
    }
    
    Ensure the terms are realistic for the credit variance and profile provided.
    `;

    try {
      return await this.openRouter.getJson<LoanRecommendationResult>(prompt);
    } catch (error) {
      console.error('Loan recommendation failed', error);
      // Fallback
      return {
        primary: {
          offer: {
            id: 'fallback-sbi',
            bank: 'State Bank of India',
            name: 'SBI Global Ed-Vantage',
            minScore: 60,
            minCredit: 700,
            minRatio: 0.1,
            maxLoan: 15000000,
            requiresCoApplicant: true,
            requiresCollateral: true,
            apr: '8.15% - 9.50%',
            coverage: 'Up to 100%',
            bestFor: 'Lowest interest rates'
          },
          fit: 85
        },
        alternatives: [
          {
            offer: {
              id: 'fallback-hdfc',
              bank: 'HDFC Credila',
              name: 'Unsecured Education Loan',
              minScore: 50,
              minCredit: 650,
              minRatio: 0.2,
              maxLoan: 4000000,
              requiresCoApplicant: true,
              requiresCollateral: false,
              apr: '10.75% - 12.50%',
              coverage: 'Up to 80%',
              bestFor: 'No collateral required'
            },
            fit: 75
          }
        ]
      };
    }
  }

  async recommendChatLoans(profile: any): Promise<any> {
    const prompt = `You are a student loan advisor. Recommend 3 customized student loan options for an Indian student based on the following profile:

Profile:
- Degree targeting: ${profile.degree || 'Masters'}
- Target Country: ${profile.country || 'USA'}
- Field of study: ${profile.major || 'Computer Science'}
- GPA / CGPA: ${profile.gpa || '8.0'}
- Backlogs: ${profile.backlogs || 'No'} (Count: ${profile.backlogCount || '0'})
- Standardized test status: ${profile.testStatus || 'Not taken'} (Scores: ${JSON.stringify(profile.testScores || {})})
- Admission status: ${profile.admitStatus || 'Yet to Apply'}
- Pincode: ${profile.pincode || 'N/A'}
- Co-signer relationship: ${profile.cosignerRelation || 'Parent'}
- Co-signer type: ${profile.cosignerType || 'Salaried'}
- Co-signer monthly income: ${profile.cosignerIncome || 'N/A'}
- Collateral value: ${profile.collateralValue || 'N/A'}
- Work experience: ${profile.experience || 'None'} months

Task:
1. Generate one "primary" best-fit loan offer.
2. Generate two "alternative" loan offers.
3. For each offer, generate the following fields exactly:
   - id: Unique string ID (e.g. sbi-global, hdfc-unsecured, prodigy-finance, auxilo-abroad)
   - bank: Lenders Name (e.g. State Bank of India, HDFC Credila, Auxilo, Avanse, Prodigy Finance, MPOWER Financing, etc.)
   - name: Loan scheme name (e.g. SBI Global Ed-Vantage, Unsecured Study Abroad Loan)
   - amount: Maximum loan amount offered as a string (e.g. "₹1.5 Crore", "₹50 Lakhs", "$100,000")
   - rate: Annual Interest Rate range as a string (e.g. "8.55% - 9.50%", "10.75% - 11.50%")
   - processingTime: Expected time to process as a string (e.g. "5-7 working days", "2-3 weeks")
   - savings: Estimated savings/benefits or unique perk as a string (e.g. "Zero processing fee online", "0.5% interest concession for female students", "No collateral required")
   - requiresCoApplicant: boolean (true or false)
   - requiresCollateral: boolean (true or false)
   - bestFor: Short text indicating why this is best for this profile (e.g. "Low interest rate with collateral", "Unsecured funding for top universities")
   - fit: A numeric percentage value representing suitability for this profile (e.g., 92, 85)

Return strictly valid JSON in this exact structure:
{
  "primary": {
    "offer": {
      "id": "...",
      "bank": "...",
      "name": "...",
      "amount": "...",
      "rate": "...",
      "processingTime": "...",
      "savings": "...",
      "requiresCoApplicant": false,
      "requiresCollateral": false,
      "bestFor": "..."
    },
    "fit": 95
  },
  "alternatives": [
    {
      "offer": {
        "id": "...",
        "bank": "...",
        "name": "...",
        "amount": "...",
        "rate": "...",
        "processingTime": "...",
        "savings": "...",
        "requiresCoApplicant": false,
        "requiresCollateral": false,
        "bestFor": "..."
      },
      "fit": 80
    },
    {
      "offer": {
        "id": "...",
        "bank": "...",
        "name": "...",
        "amount": "...",
        "rate": "...",
        "processingTime": "...",
        "savings": "...",
        "requiresCoApplicant": false,
        "requiresCollateral": false,
        "bestFor": "..."
      },
      "fit": 75
    }
  ]
}`;

    try {
      return await this.openRouter.getJson<any>(prompt);
    } catch (e) {
      console.error('[LoanRecommendationService] Chat recommendations failed, using static fallback:', e);
      return {
        primary: {
          offer: {
            id: 'sbi-global',
            bank: 'State Bank of India',
            name: 'SBI Global Ed-Vantage',
            amount: 'Up to ₹1.5 Crore',
            rate: '8.55% - 9.50%',
            processingTime: '7-14 working days',
            savings: 'Concession for female students',
            requiresCoApplicant: true,
            requiresCollateral: true,
            bestFor: 'Lowest interest rates with collateral'
          },
          fit: 90
        },
        alternatives: [
          {
            offer: {
              id: 'hdfc-credila',
              bank: 'HDFC Credila',
              name: 'Unsecured Abroad Loan',
              amount: 'Up to ₹50 Lakhs',
              rate: '10.50% - 12.00%',
              processingTime: '3-5 working days',
              savings: 'Fast online processing',
              requiresCoApplicant: true,
              requiresCollateral: false,
              bestFor: 'Unsecured loan without collateral'
            },
            fit: 80
          },
          {
            offer: {
              id: 'prodigy-abroad',
              bank: 'Prodigy Finance',
              name: 'International Student Funding',
              amount: 'Up to $100,000',
              rate: '11.20% - 13.50%',
              processingTime: '2-4 working days',
              requiresCoApplicant: false,
              requiresCollateral: false,
              savings: 'No co-signer or collateral required',
              bestFor: 'Top international MBA/MS programs'
            },
            fit: 75
          }
        ]
      };
    }
  }
}
