import { OnboardingService } from './onboarding.service';
export declare class OnboardingController {
    private onboardingService;
    constructor(onboardingService: OnboardingService);
    saveOnboardingData(body: any, req: any): Promise<{
        success: boolean;
        message: string;
        user?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        user: any;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        error: any;
        user?: undefined;
    }>;
    getStatus(req: any): Promise<{
        success: boolean;
        isCompleted: boolean;
        user: any;
    }>;
    shareOnboardingLink(body: any, req: any): Promise<{
        success: boolean;
        message: string;
        error: any;
    } | {
        success: boolean;
        message: string;
    }>;
}
