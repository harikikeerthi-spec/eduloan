"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var OpenRouterService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OpenRouterService = void 0;
const common_1 = require("@nestjs/common");
let OpenRouterService = OpenRouterService_1 = class OpenRouterService {
    logger = new common_1.Logger(OpenRouterService_1.name);
    apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    apiKey = process.env.OPENROUTER_API_KEY;
    async generateResponse(systemPrompt, userPrompt, temperature = 0.7, maxTokens = 2048) {
        if (!this.apiKey) {
            this.logger.warn('OPENROUTER_API_KEY is not set');
            throw new Error('API key is missing');
        }
        let attempts = 0;
        const maxAttempts = 3;
        let lastError;
        while (attempts < maxAttempts) {
            try {
                attempts++;
                if (attempts > 1) {
                    this.logger.log(`Retry attempt ${attempts}/${maxAttempts} for OpenRouter API...`);
                    await new Promise((resolve) => setTimeout(resolve, 1000 * attempts));
                }
                const response = await fetch(this.apiUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        Authorization: `Bearer ${this.apiKey}`,
                        'HTTP-Referer': 'http://localhost:3000',
                        'X-Title': 'VidhyaLoan AI Service',
                    },
                    body: JSON.stringify({
                        model: 'google/gemini-2.5-flash',
                        messages: [
                            { role: 'system', content: systemPrompt },
                            { role: 'user', content: userPrompt },
                        ],
                        temperature: temperature,
                        max_tokens: maxTokens,
                    }),
                });
                if (!response.ok) {
                    const errorText = await response.text();
                    this.logger.error(`OpenRouter API error: ${response.status} ${response.statusText} - ${errorText}`);
                    throw new Error(`OpenRouter API failed (${response.status}): ${errorText}`);
                }
                const data = await response.json();
                if (data.error) {
                    throw new Error(`OpenRouter API failed (${response.status}): ${JSON.stringify(data.error)}`);
                }
                if (!data.choices || data.choices.length === 0) {
                    this.logger.error('No choices returned from OpenRouter:', JSON.stringify(data));
                    throw new Error('No completion returned from OpenRouter');
                }
                const text = data.choices[0].message?.content;
                if (!text) {
                    this.logger.error('Empty content in message:', JSON.stringify(data.choices[0]));
                    throw new Error('Empty text content from OpenRouter');
                }
                return text;
                return text;
            }
            catch (error) {
                lastError = error;
                this.logger.error(`Attempt ${attempts} failed: ${error.message}`);
            }
        }
        this.logger.error('All attempts to call OpenRouter API failed', lastError);
        throw lastError;
    }
};
exports.OpenRouterService = OpenRouterService;
exports.OpenRouterService = OpenRouterService = OpenRouterService_1 = __decorate([
    (0, common_1.Injectable)()
], OpenRouterService);
//# sourceMappingURL=open-router.service.js.map