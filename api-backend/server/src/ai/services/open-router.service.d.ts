export declare class OpenRouterService {
    private readonly logger;
    private readonly apiUrl;
    private readonly apiKey;
    generateResponse(systemPrompt: string, userPrompt: string, temperature?: number, maxTokens?: number): Promise<string>;
}
