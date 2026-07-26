import { ReferralService } from './referral.service';
export declare class ReferralController {
    private readonly referralService;
    constructor(referralService: ReferralService);
    getMyCode(req: any): Promise<{
        referralCode: any;
        user: {
            id: any;
            referralCode: any;
            firstName: any;
            lastName: any;
            email: any;
        };
        success: boolean;
    }>;
    getStats(req: any): Promise<{
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
        success: boolean;
    }>;
    getReferralList(req: any): Promise<{
        success: boolean;
        referrals: {
            id: any;
            refereeEmail: any;
            refereeName: string | null;
            status: any;
            reward: any;
            createdAt: any;
            completedAt: any;
        }[];
    }>;
    validateCode(code: string): Promise<{
        valid: boolean;
        referrerName?: undefined;
        success: boolean;
    } | {
        valid: boolean;
        referrerName: string;
        success: boolean;
    }>;
    recordReferral(body: {
        referralCode: string;
        refereeEmail: string;
        refereeId?: string;
    }): Promise<{
        success: boolean;
        message: string;
        referral?: undefined;
    } | {
        success: boolean;
        referral: any;
        message?: undefined;
    }>;
    sendInvite(req: any, body: {
        email: string;
    }): Promise<{
        success: boolean;
        message: string;
        referral?: undefined;
    } | {
        success: boolean;
        referral: any;
        message?: undefined;
    }>;
    getLeaderboard(limit?: string): Promise<{
        success: boolean;
        leaderboard: {
            rank: number;
            name: string;
            count: number;
        }[];
    }>;
    recordVisit(code: string, req: any): Promise<{
        success: boolean;
        message?: undefined;
    } | {
        success: boolean;
        message: any;
    }>;
}
