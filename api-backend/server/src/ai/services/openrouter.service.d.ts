export declare class OpenRouterService {
    private readonly apiUrl;
    private readonly apiKey;
    private readonly REQUEST_TIMEOUT_MS;
    private readonly FALLBACK_MODELS;
    private readonly VISION_FALLBACK_MODELS;
    private createTimeoutSignal;
    chat(prompt: string, model?: string): Promise<string>;
    getJson<T>(prompt: string, model?: string): Promise<T>;
    searchAdvice(query: string, type: 'university' | 'course' | 'ug_university', context?: any): Promise<any[]>;
    chatWithVision(prompt: string, imageUrl: string, model?: string): Promise<string>;
}
