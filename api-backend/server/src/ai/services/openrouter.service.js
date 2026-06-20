"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OpenRouterService = void 0;
const common_1 = require("@nestjs/common");
let OpenRouterService = class OpenRouterService {
    apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    apiKey = process.env.OPENROUTER_API_KEY;
    REQUEST_TIMEOUT_MS = 30_000;
    FALLBACK_MODELS = [
        'meta-llama/llama-3.3-70b-instruct:free',
        'openrouter/free',
        'meta-llama/llama-3.2-3b-instruct:free',
        'openai/gpt-4o-mini',
    ];
    VISION_FALLBACK_MODELS = [
        'openai/gpt-4o-mini',
        'openrouter/free',
        'meta-llama/llama-3.2-11b-vision-instruct:free',
    ];
    createTimeoutSignal() {
        return AbortSignal.timeout(this.REQUEST_TIMEOUT_MS);
    }
    async chat(prompt, model = 'openai/gpt-4o-mini') {
        if (!this.apiKey || this.apiKey === 'your_openrouter_api_key_here') {
            console.warn('OPENROUTER_API_KEY is not set. Using mock response or failing.');
            throw new Error('OPENROUTER_API_KEY is not configured in environment variables.');
        }
        const requestBody = {
            model: model,
            messages: [
                { role: 'user', content: prompt }
            ],
            max_tokens: 2048,
        };
        const maskedKey = this.apiKey ? `${this.apiKey.slice(0, 4)}...${this.apiKey.slice(-4)} (len ${this.apiKey.length})` : '[NOT SET]';
        console.log('OpenRouter request:', {
            url: this.apiUrl,
            model: requestBody.model,
            promptLength: prompt.length,
            openRouterKey: maskedKey
        });
        try {
            const response = await fetch(this.apiUrl, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.apiKey}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'https://vidyaloan.com',
                    'X-Title': 'VidyaLoan',
                },
                body: JSON.stringify(requestBody),
                signal: this.createTimeoutSignal(),
            });
            if (!response.ok) {
                const errorBody = await response.text();
                console.error('OpenRouter API error details:', {
                    status: response.status,
                    statusText: response.statusText,
                    body: errorBody
                });
                throw new Error(`OpenRouter API error: ${response.statusText} - ${errorBody}`);
            }
            const data = await response.json();
            return data.choices?.[0]?.message?.content || '';
        }
        catch (error) {
            console.error('OpenRouter request failed:', error?.message || error);
            if (error?.name === 'TimeoutError' || error?.name === 'AbortError' || error?.message?.includes('timed out')) {
                console.warn('OpenRouter request timed out after', this.REQUEST_TIMEOUT_MS, 'ms');
                if (prompt.includes('universities')) {
                    return JSON.stringify({ universities: [] });
                }
                return "Our AI assistant is temporarily busy. Please try again in a few minutes.";
            }
            if (error?.message?.includes('429') || error?.message?.includes('rate_limit')) {
                console.warn('Rate limit hit. Returning mock response for stability.');
                if (prompt.includes('universities')) {
                    return JSON.stringify([{
                            name: "Stanford University (Mock)", loc: "California, USA", slug: "stanford",
                            rank: 3, accept: 4, tuition: 55000, country: "USA", description: "A top research university."
                        }]);
                }
                return "Our AI assistant is temporarily busy due to high demand. Please try again in a few minutes.";
            }
            throw error;
        }
    }
    async getJson(prompt, model = 'meta-llama/llama-3.3-70b-instruct:free') {
        const jsonPrompt = `${prompt}\n\nIMPORTANT: Respond ONLY with valid JSON. Do not include markdown formatting.`;
        if (!this.apiKey || this.apiKey === 'your_openrouter_api_key_here')
            throw new Error('OPENROUTER_API_KEY is not configured');
        const modelsToTry = [model, ...this.FALLBACK_MODELS].filter((m, i, a) => a.indexOf(m) === i);
        let lastError = null;
        let content = '';
        for (const currentModel of modelsToTry) {
            try {
                const response = await fetch(this.apiUrl, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${this.apiKey}`,
                        'Content-Type': 'application/json',
                        'HTTP-Referer': 'https://vidyaloan.com',
                        'X-Title': 'VidyaLoan',
                    },
                    body: JSON.stringify({
                        model: currentModel,
                        messages: [{ role: 'user', content: jsonPrompt }],
                        response_format: { type: "json_object" },
                        max_tokens: 2048,
                    }),
                    signal: this.createTimeoutSignal(),
                });
                if (response.ok) {
                    const data = await response.json();
                    content = data.choices?.[0]?.message?.content || '';
                    if (content) {
                        console.log(`[getJson] Successfully used model: ${currentModel}`);
                        break;
                    }
                }
                else {
                    const errorBody = await response.text();
                    if (response.status === 404 && (errorBody.includes('No endpoints found') || errorBody.includes('does not exist'))) {
                        console.warn(`Model ${currentModel} not found (404). Trying fallback model...`);
                        lastError = new Error(`Model not found: ${currentModel}`);
                        continue;
                    }
                    else if (response.status === 400 && errorBody.includes('json_validate_failed')) {
                        console.warn(`Model ${currentModel}: Native JSON mode failed. Retrying with standard mode...`);
                        content = await this.chat(jsonPrompt, currentModel);
                        if (content)
                            break;
                    }
                    else if (response.status === 429 || errorBody.includes('rate_limit')) {
                        console.warn(`Model ${currentModel}: Rate limited. Trying fallback...`);
                        lastError = new Error(`Rate limit hit for ${currentModel}`);
                        continue;
                    }
                    else {
                        console.warn(`Model ${currentModel} failed with status ${response.status}. Trying fallback...`);
                        lastError = new Error(`OpenRouter error: ${response.statusText}`);
                        continue;
                    }
                }
            }
            catch (error) {
                console.warn(`[getJson] Model ${currentModel} attempt failed:`, error?.message || error);
                lastError = error;
                if (error?.name === 'TimeoutError' || error?.name === 'AbortError' || error?.message?.includes('timed out')) {
                    continue;
                }
                continue;
            }
        }
        if (!content && lastError) {
            console.error('All getJson models failed. Returning empty result.');
            if (prompt.includes('universities'))
                return { universities: [] };
            if (prompt.includes('courses'))
                return { courses: [] };
            return {};
        }
        try {
            let cleaned = content.replace(/```json/g, '').replace(/```/g, '').trim();
            const firstBrace = cleaned.indexOf('{');
            const firstBracket = cleaned.indexOf('[');
            let start = -1;
            let end = -1;
            if (firstBrace !== -1 && (firstBracket === -1 || (firstBrace < firstBracket && firstBrace !== -1))) {
                start = firstBrace;
                end = cleaned.lastIndexOf('}');
            }
            else if (firstBracket !== -1) {
                start = firstBracket;
                end = cleaned.lastIndexOf(']');
            }
            if (start === -1 || end === -1 || end < start) {
                if (prompt.includes('universities'))
                    return { universities: [] };
                throw new Error('No valid JSON structure found in response');
            }
            let jsonString = cleaned.slice(start, end + 1);
            jsonString = jsonString.replace(/:\s*(\d+)-(\d+)\s*(,|})/g, ': "$1-$2"$3');
            return JSON.parse(jsonString);
        }
        catch (e) {
            console.error('Failed to parse JSON response:', content);
            if (prompt.includes('universities'))
                return { universities: [] };
            throw new Error(`AI response was not valid JSON: ${e.message}`);
        }
    }
    async searchAdvice(query, type, context) {
        let prompt = '';
        if (type === 'university') {
            const country = context?.country || '';
            const course = context?.course || '';
            prompt = `Search for REAL, ACCREDITED universities for international students.
            ${query ? `If the query "${query}" matches or represents a specific university, that exact university MUST be included in the results (ideally as the very first item). Otherwise, return universities matching or relevant to "${query}".` : 'Return popular universities.'}
            ${country ? `PRIORITY: Focus PRIMARILY on universities located in "${country}".` : ''}
            ${course ? `SECONDARY FOCUS: Universities strong in "${course}".` : ''}
            CRITICAL REQUIREMENT: Focus on finding top universities that have the HIGHEST acceptance rates for international students. Ensure the acceptance rate data is highly accurate. Please rank the returned universities in descending order of their acceptance rates (highest to lowest) (with the exception of the exact name match which should always be included).

            Context Details: ${JSON.stringify(context || {})}

            Requirement: Return a JSON object with a "universities" key.
            The "universities" key should be an array of up to 12 objects.
            For each university, provide:
            - name, loc, slug, rank, accept, tuition, country, description, website, courses

            MUST respond ONLY with JSON.`;
        }
        else if (type === 'ug_university') {
            prompt = `Search for REAL undergraduate degree or engineering colleges/universities matching or relevant to "${query || ''}". 
            IMPORTANT: Return ONLY colleges and universities located in INDIA. Do not include institutions from any other country.
            Return a JSON object with a "universities" key.
            The "universities" key should be an array of up to 5 objects.
            For each university, provide:
            - name, loc (City, State), pincode
            
            MUST respond ONLY with JSON.`;
        }
        else {
            const university = context?.university || '';
            const degree = context?.degree || 'masters';
            prompt = `Provide a comprehensive list of popular and valid courses/fields of study ${university ? `offered at ${university}` : ''} ${degree ? `for a ${degree} degree` : ''} ${query ? `matching or relevant to "${query}"` : ''}.
            Return a JSON object with a "courses" key.
            The "courses" key should be an array of up to 15-20 distinct and high-demand courses/programs.
            For each course, provide an object with a "name" key containing the course title (e.g., "MS Computer Science", "MBA").
            MUST respond ONLY with JSON.`;
        }
        const res = await this.getJson(prompt);
        return ((res && (res.universities || res.courses)) || []);
    }
    async chatWithVision(prompt, imageUrl, model = 'openai/gpt-4o-mini') {
        if (!this.apiKey || this.apiKey === 'your_openrouter_api_key_here') {
            throw new Error('OPENROUTER_API_KEY is not configured');
        }
        const modelsToTry = Array.from(new Set([
            model,
            ...this.VISION_FALLBACK_MODELS,
        ]));
        let lastError = null;
        for (const currentModel of modelsToTry) {
            console.log(`[OpenRouter Vision] Attempting extraction with model: ${currentModel}...`);
            const isPdf = imageUrl.startsWith('data:application/pdf');
            const requestBody = {
                model: currentModel,
                messages: [
                    {
                        role: 'user',
                        content: [
                            { type: 'text', text: prompt },
                            isPdf ? {
                                type: 'file',
                                file: {
                                    filename: 'document.pdf',
                                    file_data: imageUrl
                                }
                            } : {
                                type: 'image_url',
                                image_url: { url: imageUrl }
                            }
                        ]
                    }
                ],
                max_tokens: 4096,
                temperature: 0.1,
            };
            try {
                const response = await fetch(this.apiUrl, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${this.apiKey}`,
                        'Content-Type': 'application/json',
                        'HTTP-Referer': 'https://vidyaloan.com',
                        'X-Title': 'VidyaLoan',
                    },
                    body: JSON.stringify(requestBody),
                    signal: this.createTimeoutSignal(),
                });
                if (!response.ok) {
                    const errorBody = await response.text();
                    if (response.status === 404 && (errorBody.includes('No endpoints found') || errorBody.includes('does not exist'))) {
                        console.warn(`[OpenRouter Vision] Model ${currentModel} not found (404). Trying next model...`);
                        lastError = new Error(`Model not found: ${currentModel}`);
                        continue;
                    }
                    throw new Error(`OpenRouter Vision API error: ${response.status} - ${errorBody}`);
                }
                const data = await response.json();
                const content = data.choices?.[0]?.message?.content;
                if (content) {
                    console.log(`[OpenRouter Vision] Successfully extracted details using model: ${currentModel}`);
                    return content;
                }
            }
            catch (err) {
                console.warn(`[OpenRouter Vision] Model ${currentModel} failed: ${err.message || err}`);
                lastError = err;
                continue;
            }
        }
        throw lastError || new Error('All vision endpoints failed to respond.');
    }
};
exports.OpenRouterService = OpenRouterService;
exports.OpenRouterService = OpenRouterService = __decorate([
    (0, common_1.Injectable)()
], OpenRouterService);
//# sourceMappingURL=openrouter.service.js.map