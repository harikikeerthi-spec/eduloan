import { OpenRouterService } from './openrouter.service';
import { SupabaseService } from '../../supabase/supabase.service';
export interface EligibilityCheckDto {
    age: number;
    credit: number;
    income: number;
    loan: number;
    employment: 'employed' | 'self' | 'student' | 'unemployed';
    study: 'undergrad' | 'masters' | 'doctoral' | 'diploma';
    coApplicant: 'yes' | 'no';
    collateral: 'yes' | 'no';
}
export interface EligibilityResult {
    score: number;
    status: 'eligible' | 'borderline' | 'unlikely';
    ratio: number;
    rateRange: string;
    coverage: string;
    summary: string;
    recommendations: string[];
}
export declare class EligibilityService {
    private readonly openRouter;
    private readonly supabase;
    constructor(openRouter: OpenRouterService, supabase: SupabaseService);
    calculateEligibilityScore(data: EligibilityCheckDto): Promise<EligibilityResult>;
    saveLog(data: any): Promise<void>;
}
