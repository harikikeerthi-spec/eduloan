export declare class GrokService {
    private readonly apiUrl;
    private readonly apiKey;
    chat(prompt: string, model?: string): Promise<string>;
    getJson<T>(prompt: string, model?: string): Promise<T>;
}
