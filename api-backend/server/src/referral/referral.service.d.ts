import { SupabaseService } from '../supabase/supabase.service';
export declare class ReferralService {
    private readonly supabase;
    private readonly logger;
    private get db();
    constructor(supabase: SupabaseService);
    handleApplicationDisbursed(event: {
        applicationId: string;
        userId: string;
        amount: number;
        bankId?: string;
    }): Promise<void>;
    private generateCode;
    getOrCreateReferralCode(userId: string): Promise<{
        referralCode: any;
        user: {
            id: any;
            referralCode: any;
            firstName: any;
            lastName: any;
            email: any;
        };
    }>;
    getReferralStats(userId: string): Promise<{
        referralCode: any;
        firstName: any;
        totalReferrals: number;
        completedReferrals: number;
        signedUpReferrals: number;
        pendingReferrals: number;
        totalVisits: number;
        tier: string;
        nextTierAt: number | null;
        rewards: {
            name: string;
            unlocked: boolean;
            at?: number;
        }[];
    }>;
    getReferralList(userId: string): Promise<{
        id: any;
        refereeEmail: any;
        refereeName: string | null;
        status: any;
        reward: any;
        createdAt: any;
        completedAt: any;
    }[]>;
    validateReferralCode(code: string): Promise<{
        valid: boolean;
        referrerName?: undefined;
    } | {
        valid: boolean;
        referrerName: string;
    }>;
    recordReferral(referralCode: string, refereeEmail: string, refereeId?: string): Promise<any>;
    completeReferral(refereeId: string): Promise<any>;
    sendInvite(userId: string, email: string): Promise<any>;
    getLeaderboard(limit?: number): Promise<{
        rank: number;
        name: string;
        count: number;
    }[]>;
    private calculateRewards;
    private getRewardForCount;
    recordVisit(code: string, ipAddress?: string, userAgent?: string): Promise<any>;
}
