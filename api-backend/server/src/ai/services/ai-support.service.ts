import { Injectable, Logger } from '@nestjs/common';
import { OpenRouterService } from './openrouter.service';

@Injectable()
export class AiSupportService {
  private readonly logger = new Logger(AiSupportService.name);

  constructor(private readonly openRouterService: OpenRouterService) {}

  async getResponse(userMessage: string, history: any[] = []): Promise<string> {
    const systemPrompt = `You are VidhyaLoan AI Support Assistant, a friendly, intelligent, and highly knowledgeable education loan counselor and customer support expert for the VidhyaLoan platform.

Key Information about VidhyaLoan:
- Education Loan Aggregator & Platform: We partner with India's top banks & NBFCs (SBI, HDFC Credila, Avanse, InCred, ICICI, Axis Bank, Union Bank, Prodigy Finance, and MPOWER).
- Rates: Starting from 8.5% p.a. for secured loans and 9.75%–11.5% for unsecured loans.
- Loan Amounts: Up to ₹75 Lakhs+ without collateral (unsecured) and ₹1.5+ Crores with collateral (secured).
- Covered Destinations: USA, UK, Canada, Germany, Australia, Ireland, Europe, and India.
- Services: 100% free loan assistance, rapid sanction letter for visa filing, and expert counselors.
- Tools in App: Eligibility Checker, EMI Calculator, University Shortlisting & Comparator, SOP Reviewer, Admit Predictor, and AI Visa Interview Simulator.
- Official Support Email: support@vidyaloans.in | Support Phone: +91 92402 09000.

Tone & Guidelines:
- Be encouraging, polite, concise, and structured (use clean bullet points where appropriate).
- Answer questions directly and clearly.
- If user asks about their application or wants a loan, encourage them to submit an application via the "Apply for Loan" tab in the app.`;

    try {
      const messages: { role: string; content: string }[] = [
        { role: 'system', content: systemPrompt },
      ];

      if (Array.isArray(history)) {
        history.slice(-6).forEach((msg: any) => {
          const role = msg.role || (msg.sender === 'user' ? 'user' : 'assistant');
          const content = msg.content || msg.text || '';
          if (content) {
            messages.push({ role, content });
          }
        });
      }

      messages.push({ role: 'user', content: userMessage });

      return await this.openRouterService.chatWithMessages(messages);
    } catch (error) {
      this.logger.error('Failed to generate support response', error);
      return this.getFallback(userMessage);
    }
  }

  private getFallback(userMessage: string): string {
    const lower = userMessage.toLowerCase();
    if (lower.includes('document') || lower.includes('doc')) {
      return "Required documents for an education loan typically include:\n• Student KYC: Passport, Aadhaar, PAN card\n• Academic proof: 10th, 12th, Degree transcripts & entrance exam scores (GRE/IELTS/TOEFL)\n• University Admission: Official admit letter & fee structure\n• Co-applicant: Income proof (salary slips / ITR) and 6 months bank statements.";
    }
    if (lower.includes('interest') || lower.includes('rate') || lower.includes('roi')) {
      return "Education loan interest rates on VidhyaLoan start from 8.5% p.a. for secured loans (with property/FD collateral) and 9.75% to 11.5% for unsecured loans (without collateral), depending on your academic profile and choice of country.";
    }
    if (lower.includes('collateral') || lower.includes('unsecured')) {
      return "VidhyaLoan provides non-collateral (unsecured) loans up to ₹75 Lakhs for premier global universities. For higher amounts up to ₹1.5+ Crores, secured loans backed by residential or commercial property or fixed deposits are available at lower rates.";
    }
    if (lower.includes('contact') || lower.includes('support') || lower.includes('number') || lower.includes('phone') || lower.includes('call')) {
      return "You can contact VidhyaLoan official support anytime via email at support@vidyaloans.in or call our team at +91 92402 09000.";
    }
    return "Hello! I am your VidhyaLoan AI Support Assistant. I can help you with education loan eligibility, required documents, interest rates, university comparison, and application guidance. How can I assist you today?";
  }
}
