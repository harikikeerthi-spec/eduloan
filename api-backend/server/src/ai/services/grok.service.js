"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GrokService = void 0;
const common_1 = require("@nestjs/common");
let GrokService = class GrokService {
    apiUrl = 'https://api.x.ai/v1/chat/completions';
    apiKey = process.env.GROK_API_KEY;
    async chat(prompt, model = 'grok-beta') {
        if (!this.apiKey) {
            console.warn('GROK_API_KEY is not set. Using mock response or failing.');
            throw new Error('GROK_API_KEY is not configured in environment variables.');
        }
        const requestBody = {
            model: model,
            messages: [
                { role: 'user', content: prompt }
            ],
        };
        const maskedKey = this.apiKey ? `${this.apiKey.slice(0, 4)}...${this.apiKey.slice(-4)} (len ${this.apiKey.length})` : '[NOT SET]';
        console.log('Grok request:', {
            url: this.apiUrl,
            model: requestBody.model,
            promptLength: prompt.length,
            grokKey: maskedKey
        });
        try {
            const response = await fetch(this.apiUrl, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.apiKey}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(requestBody),
            });
            if (!response.ok) {
                const errorBody = await response.text();
                console.error('Grok API error details:', {
                    status: response.status,
                    statusText: response.statusText,
                    body: errorBody
                });
                throw new Error(`Grok API error: ${response.statusText} - ${errorBody}`);
            }
            const data = await response.json();
            return data.choices?.[0]?.message?.content || '';
        }
        catch (error) {
            console.error('Grok request failed:', error);
            throw error;
        }
    }
    async getJson(prompt, model = 'grok-beta') {
        const jsonPrompt = `${prompt}\n\nIMPORTANT: Respond ONLY with valid JSON. Do not include markdown formatting like \`\`\`json.`;
        const content = await this.chat(jsonPrompt, model);
        try {
            const cleaned = content.replace(/```json/g, '').replace(/```/g, '').trim();
            return JSON.parse(cleaned);
        }
        catch (e) {
            console.error('Failed to parse JSON response:', content);
            throw new Error('AI response was not valid JSON');
        }
    }
};
exports.GrokService = GrokService;
exports.GrokService = GrokService = __decorate([
    (0, common_1.Injectable)()
], GrokService);
//# sourceMappingURL=grok.service.js.map