
import { Injectable } from '@nestjs/common';

@Injectable()
export class OpenRouterService {
    private readonly apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    private readonly apiKey = process.env.OPENROUTER_API_KEY;
    private readonly REQUEST_TIMEOUT_MS = 30_000; // 30 seconds
    
    // Fallback models to try if primary model fails (free models first, paid as backup)
    private readonly FALLBACK_MODELS = [
        'meta-llama/llama-3.3-70b-instruct:free',
        'openrouter/free',
        'meta-llama/llama-3.2-3b-instruct:free',
        'openai/gpt-4o-mini',
    ];
    
    private readonly VISION_FALLBACK_MODELS = [
        'openai/gpt-4o-mini',
        'openrouter/free',
        'meta-llama/llama-3.2-11b-vision-instruct:free',
    ];

    /** Create an AbortSignal that auto-aborts after the configured timeout. */
    private createTimeoutSignal(): AbortSignal {
        return AbortSignal.timeout(this.REQUEST_TIMEOUT_MS);
    }

    async chat(prompt: string, model: string = 'openai/gpt-4o-mini'): Promise<string> {
        if (!this.apiKey || this.apiKey === 'your_openrouter_api_key_here') {
            console.warn('OPENROUTER_API_KEY is not set. Using mock response or failing.');
            throw new Error('OPENROUTER_API_KEY is not configured in environment variables.');
        }

        const requestBody: any = {
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
        } catch (error) {
            console.error('OpenRouter request failed:', error?.message || error);
            // Handle timeout errors
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

    async getJson<T>(prompt: string, model: string = 'meta-llama/llama-3.3-70b-instruct:free'): Promise<T> {
        const jsonPrompt = `${prompt}\n\nIMPORTANT: Respond ONLY with valid JSON. Do not include markdown formatting.`;
        if (!this.apiKey || this.apiKey === 'your_openrouter_api_key_here') throw new Error('OPENROUTER_API_KEY is not configured');

        // Build list of models to try
        const modelsToTry = [model, ...this.FALLBACK_MODELS].filter((m, i, a) => a.indexOf(m) === i); // Remove duplicates
        let lastError: Error | null = null;

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

                let content = '';
                if (response.ok) {
                    const data = await response.json();
                    content = data.choices?.[0]?.message?.content || '';
                } else {
                    const errorBody = await response.text();
                    if (response.status === 404 && (errorBody.includes('No endpoints found') || errorBody.includes('does not exist'))) {
                        console.warn(`Model ${currentModel} not found (404). Trying fallback model...`);
                        lastError = new Error(`Model not found: ${currentModel}`);
                        continue; // Try next model
                    } else if (response.status === 400 && errorBody.includes('json_validate_failed')) {
                        console.warn(`Model ${currentModel}: Native JSON mode failed. Retrying with standard mode...`);
                        content = await this.chat(jsonPrompt, currentModel);
                    } else if (response.status === 429 || errorBody.includes('rate_limit')) {
                        console.warn(`Model ${currentModel}: Rate limited. Trying fallback...`);
                        lastError = new Error(`Rate limit hit for ${currentModel}`);
                        continue;
                    } else {
                        console.warn(`Model ${currentModel} failed with status ${response.status}. Trying fallback...`);
                        lastError = new Error(`OpenRouter error: ${response.statusText}`);
                        continue;
                    }
                }

                if (content) {
                    try {
                        let cleaned = content.replace(/```json/g, '').replace(/```/g, '').trim();
                        const firstBrace = cleaned.indexOf('{');
                        const firstBracket = cleaned.indexOf('[');
                        let start = -1;
                        let end = -1;

                        if (firstBrace !== -1 && (firstBracket === -1 || (firstBrace < firstBracket && firstBrace !== -1))) {
                            start = firstBrace;
                            end = cleaned.lastIndexOf('}');
                        } else if (firstBracket !== -1) {
                            start = firstBracket;
                            end = cleaned.lastIndexOf(']');
                        }

                        if (start === -1 || end === -1 || end < start) {
                            throw new Error('No valid JSON structure found in response');
                        }

                        let jsonString = cleaned.slice(start, end + 1);
                        jsonString = jsonString.replace(/:\s*(\d+)-(\d+)\s*(,|})/g, ': "$1-$2"$3');
                        const parsed = JSON.parse(jsonString) as T;
                        console.log(`[getJson] Successfully used model and parsed JSON: ${currentModel}`);
                        return parsed; // Successfully parsed! Return immediately
                    } catch (parseError) {
                        console.warn(`[getJson] Model ${currentModel} returned content but failed to parse as valid JSON:`, parseError.message);
                        lastError = parseError as Error;
                        // Continue to try the next model
                    }
                }
            } catch (error) {
                console.warn(`[getJson] Model ${currentModel} attempt failed:`, error?.message || error);
                lastError = error as Error;
                continue;
            }
        }

        if (lastError) {
            console.error('All getJson models failed. Returning empty result or throwing.');
            if (prompt.includes('universities')) return { recommendations: [], universities: [] } as any;
            if (prompt.includes('courses')) return { courses: [] } as any;
            throw lastError;
        }

        throw new Error('All models failed without specific errors.');
    }

    async searchAdvice(query: string, type: 'university' | 'course' | 'ug_university', context?: any): Promise<any[]> {
        let prompt = '';
        let finalType = type;
        let finalQuery = query;
        let finalContext = { ...context };

        const isUgUniversity = finalType === 'ug_university' || 
          finalContext?.degree === "Bachelor's" || 
          finalContext?.degree === 'bachelors' || 
          finalContext?.degree === 'ug_university';

        if (isUgUniversity) {
            const country = finalContext?.country || 'India';

            prompt = `Search for REAL, ACCREDITED Indian colleges and universities where students complete their Bachelor's degree (undergraduate studies).
            ${finalQuery ? `Return Indian universities/colleges matching or relevant to "${finalQuery}" (e.g. IITs, NITs, BITS, Osmania University, Anna University, JNTU, Delhi University, Mumbai University, VTU, SRM, VIT, Manipal, LPU, Amity, Pune University, etc.).` : 'Return popular Indian universities.'}

            STRICT REQUIREMENT: Focus PRIMARILY on Indian universities and colleges (located in India).

            Context Details: ${JSON.stringify(finalContext || {})}

            Requirement: Return a JSON object with a "universities" key.
            The "universities" key should be an array of up to 12 objects.
            For each university, provide:
            - name, loc, slug, rank, accept, tuition, country, description, website, courses

            MUST respond ONLY with JSON.`;
        } else if (finalType === 'university') {
            const country = finalContext?.country || '';
            const course = finalContext?.course || '';

            prompt = `Search for REAL, ACCREDITED universities for international students.
            ${finalQuery ? `If the query "${finalQuery}" matches or represents a specific university, that exact university MUST be included in the results (ideally as the very first item). Otherwise, return universities matching or relevant to "${finalQuery}".` : 'Return popular universities.'}
            ${country ? `PRIORITY: Focus PRIMARILY on universities located in "${country}".` : ''}
            ${course ? `SECONDARY FOCUS: Universities strong in "${course}".` : ''}
            CRITICAL REQUIREMENT: Focus on finding top universities that have the HIGHEST acceptance rates for international students. Ensure the acceptance rate data is highly accurate. Please rank the returned universities in descending order of their acceptance rates (highest to lowest) (with the exception of the exact name match which should always be included).
            
            STRICT REQUIREMENT: DO NOT return any universities or colleges located in India. All returned universities MUST be abroad/international universities (e.g. located in USA, UK, Canada, Australia, Singapore, Europe, etc.).

            Context Details: ${JSON.stringify(finalContext || {})}

            Requirement: Return a JSON object with a "universities" key.
            The "universities" key should be an array of up to 12 objects.
            For each university, provide:
            - name, loc, slug, rank, accept, tuition, country, description, website, courses

            MUST respond ONLY with JSON.`;
        } else {
            const university = context?.university || '';
            const degree = context?.degree || 'masters';
            const isBachelors = degree.toLowerCase().includes('bachelor') || degree.toLowerCase().includes('ug') || degree.toLowerCase().includes('undergrad');

            if (isBachelors) {
                prompt = `Provide a comprehensive list of popular and valid BACHELOR'S degree courses/programs ${university ? `offered at ${university}` : 'for undergraduate students'} ${query ? `matching or relevant to "${query}"` : ''}.
                EXPLICIT REQUIREMENT: Return ONLY Bachelor's level degrees such as:
                - "B.Tech in Computer Science and Engineering (CSE)"
                - "B.E. in Computer Science"
                - "B.Sc in Computer Science"
                - "B.C.A. (Bachelor of Computer Applications)"
                - "B.Tech in Information Technology"
                - "B.Tech in Electrical & Electronics Engineering"
                - "B.Tech in Mechanical Engineering"
                - "B.Com", "B.B.A.", "B.Arch"
                DO NOT return any Master's degree titles (such as MS, M.Tech, MBA, BS).

                Return a JSON object with a "courses" key.
                The "courses" key should be an array of up to 15-20 distinct Bachelor's courses.
                For each course, provide an object with a "name" key containing the course title.
                MUST respond ONLY with JSON.`;
            } else {
                prompt = `Provide a comprehensive list of popular and valid MASTER'S degree courses/programs ${university ? `offered at ${university}` : 'for graduate/master students'} ${query ? `matching or relevant to "${query}"` : ''}.
                EXPLICIT REQUIREMENT: Return ONLY Master's level degrees such as:
                - "MS in Computer Science"
                - "MS in Data Science and Analytics"
                - "MS in Software Engineering"
                - "M.Tech in Computer Science"
                - "MBA"
                DO NOT return any Bachelor's degree titles (such as B.Tech, B.E., B.Sc, B.C.A., BS).

                Return a JSON object with a "courses" key.
                The "courses" key should be an array of up to 15-20 distinct Master's courses.
                For each course, provide an object with a "name" key containing the course title.
                MUST respond ONLY with JSON.`;
            }
        }

        const res = await this.getJson<any>(prompt);
        const list = ((res && (res.universities || res.courses)) || []) as any[];

        if (finalType === 'university' && !isUgUniversity) {
            return list.filter((uni: any) => {
                if (!uni) return false;
                const uniCountry = (uni.country || '').toLowerCase();
                const uniLoc = (uni.loc || uni.location || '').toLowerCase();
                const uniName = (uni.name || '').toLowerCase();
                return !uniCountry.includes('india') && 
                       !uniLoc.includes('india') && 
                       !uniName.includes('indian institute');
            });
        }
        return list;
    }

    async chatWithVision(prompt: string, imageUrl: string, model: string = 'openai/gpt-4o-mini'): Promise<string> {
        if (!this.apiKey || this.apiKey === 'your_openrouter_api_key_here') {
            throw new Error('OPENROUTER_API_KEY is not configured');
        }

        const modelsToTry = Array.from(new Set([
            model,
            ...this.VISION_FALLBACK_MODELS,
        ]));

        let lastError: Error | null = null;
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
            } catch (err: any) {
                console.warn(`[OpenRouter Vision] Model ${currentModel} failed: ${err.message || err}`);
                lastError = err;
                // Continue to next model on error
                continue;
            }
        }
        throw lastError || new Error('All vision endpoints failed to respond.');
    }
}
