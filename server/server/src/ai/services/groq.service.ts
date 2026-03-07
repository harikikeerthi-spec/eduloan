import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class GroqService {
    private readonly logger = new Logger(GroqService.name);
    private readonly apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    private readonly apiKey = process.env.OPENROUTER_API_KEY;

    async chat(prompt: string, model: string = 'google/gemini-2.0-flash-001'): Promise<string> {
        if (!this.apiKey) {
            this.logger.warn('OPENROUTER_API_KEY is not set');
            throw new Error('API key is missing');
        }

        try {
            const response = await fetch(this.apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${this.apiKey}`,
                    'HTTP-Referer': 'http://localhost:3000',
                    'X-Title': 'EduLoan AI Service',
                },
                body: JSON.stringify({
                    model: model,
                    messages: [
                        { role: 'user', content: prompt }
                    ],
                    temperature: 0.7,
                }),
            });

            if (!response.ok) {
                const errorText = await response.text();
                this.logger.error(`OpenRouter API error: ${response.status} - ${errorText}`);
                throw new Error(`OpenRouter API failed: ${response.statusText}`);
            }

            const data = await response.json();
            const text = data.choices?.[0]?.message?.content;
            if (!text) throw new Error('Empty response from AI');

            return text;
        } catch (error) {
            this.logger.error('AI Request failed:', error);
            throw error;
        }
    }

    async getJson<T>(prompt: string, model: string = 'google/gemini-2.0-flash-001'): Promise<T> {
        const jsonPrompt = `${prompt}\n\nIMPORTANT: Respond ONLY with valid JSON. Do not include markdown formatting like \`\`\`json.`;
        const content = await this.chat(jsonPrompt, model);
        try {
            const cleaned = content.replace(/```json/g, '').replace(/```/g, '').trim();
            return JSON.parse(cleaned) as T;
        } catch (e) {
            this.logger.error('Failed to parse JSON response:', content);
            throw new Error('AI response was not valid JSON');
        }
    }
}
