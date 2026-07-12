import { OpenRouterService } from './open-router.service';
export declare class AiSupportService {
    private readonly openRouterService;
    private readonly logger;
    constructor(openRouterService: OpenRouterService);
    getResponse(userMessage: string): Promise<string>;
}
