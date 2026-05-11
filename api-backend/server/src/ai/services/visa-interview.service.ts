import { Injectable, Logger } from '@nestjs/common';
import { OpenRouterService } from './open-router.service';

@Injectable()
export class VisaInterviewService {
  private readonly logger = new Logger(VisaInterviewService.name);

  constructor(private readonly openRouterService: OpenRouterService) {}

  async startInterview(userProfile: any, visaType: string) {
    const systemPrompt = `You are a professional Visa Officer at a consulate. Your goal is to conduct a mock interview for an ${visaType} applicant.
    Applicant Profile:
    - Name: ${userProfile.firstName} ${userProfile.lastName}
    - University: ${userProfile.university}
    - Course: ${userProfile.course}
    - Financials: ${userProfile.financials}

    Instructions:
    - Greet the applicant formally.
    - Start with a simple, common introductory question for a visa interview (e.g., asking about their purpose or university).
    - Keep the question concise and realistic.
    - Return ONLY a JSON object with the following structure:
    {
      "question": "The question text",
      "currentSection": "Introduction"
    }`;

    const userPrompt = `Start the interview for ${userProfile.firstName}.`;

    try {
      const response = await this.openRouterService.generateResponse(
        systemPrompt,
        userPrompt,
      );
      // Try to parse JSON from the response
      try {
        return JSON.parse(this.cleanJsonResponse(response));
      } catch (e) {
        return {
          question: response.replace(/\{.*\}/s, '').trim() || "Hello, please tell me which university you are planning to attend?",
          currentSection: "Introduction"
        };
      }
    } catch (error) {
      this.logger.error('Failed to start visa interview', error);
      throw error;
    }
  }

  async continueInterview(data: any) {
    const { userProfile, visaType, previousQuestion, transcript, currentSection, conversationHistory } = data;

    const systemPrompt = `You are a professional Visa Officer at a consulate. You are conducting a mock interview for an ${visaType} applicant.
    Applicant Profile:
    - Name: ${userProfile.firstName} ${userProfile.lastName}
    - University: ${userProfile.university}
    - Course: ${userProfile.course}
    - Financials: ${userProfile.financials}

    Current Context:
    - Section: ${currentSection}
    - Conversation History: ${JSON.stringify(conversationHistory)}

    Instructions:
    - Based on the applicant's last answer ("${transcript}"), provide a natural follow-up question.
    - Move through standard visa interview sections: Introduction -> Academic Background -> Financials -> Future Plans -> Conclusion.
    - If the interview has covered all areas, transition to the 'Conclusion' section and thank them.
    - Return ONLY a JSON object with the following structure:
    {
      "question": "The next question or closing statement",
      "currentSection": "The updated section name"
    }`;

    const userPrompt = `The applicant said: "${transcript}" in response to "${previousQuestion}". What is your next question?`;

    try {
      const response = await this.openRouterService.generateResponse(
        systemPrompt,
        userPrompt,
      );
      try {
        return JSON.parse(this.cleanJsonResponse(response));
      } catch (e) {
        return {
          question: response.replace(/\{.*\}/s, '').trim(),
          currentSection: currentSection
        };
      }
    } catch (error) {
      this.logger.error('Failed to continue visa interview', error);
      throw error;
    }
  }

  async evaluateAnswer(data: any) {
    const { question, transcript, visaType } = data;

    const systemPrompt = `You are an expert Visa Consultant. Evaluate the following answer given during an ${visaType} interview.
    
    Question: "${question}"
    Applicant Answer: "${transcript}"

    Instructions:
    - Provide a score from 0-100.
    - Give constructive feedback.
    - List 1-3 strengths and 1-3 areas for improvement.
    - Return ONLY a JSON object:
    {
      "score": number,
      "feedback": "string",
      "strengths": ["string"],
      "improvements": ["string"]
    }`;

    try {
      const response = await this.openRouterService.generateResponse(
        systemPrompt,
        "Evaluate the answer.",
      );
      return JSON.parse(this.cleanJsonResponse(response));
    } catch (error) {
      this.logger.error('Failed to evaluate visa answer', error);
      return {
        score: 70,
        feedback: "Good effort. Try to be more specific about your goals.",
        strengths: ["Clear communication"],
        improvements: ["Add more detail"]
      };
    }
  }

  async generateFinalReport(data: any) {
    const { conversationHistory, evaluations, visaType } = data;

    const systemPrompt = `You are an expert Visa Consultant. Generate a final summary report for a mock ${visaType} interview.
    
    Conversation: ${JSON.stringify(conversationHistory)}
    Individual Evaluations: ${JSON.stringify(evaluations)}

    Instructions:
    - Summarize the overall performance.
    - Provide an estimate of visa success probability (High/Medium/Low).
    - Give 3-5 key tips for the real interview.
    - Format the report as a professional markdown document.
    - Return ONLY the markdown content.`;

    try {
      const response = await this.openRouterService.generateResponse(
        systemPrompt,
        "Generate the report.",
      );
      return { report: response };
    } catch (error) {
      this.logger.error('Failed to generate final report', error);
      return { report: "Error generating report. Please review your conversation history." };
    }
  }

  private cleanJsonResponse(response: string): string {
    // Remove markdown code blocks if present
    return response.replace(/```json\n?/, '').replace(/\n?```/, '').trim();
  }
}
