import { ReferralService } from './referral.service';
export declare class UserController {
    private readonly referralService;
    constructor(referralService: ReferralService);
    getReferralStats(req: any): Promise<{
        success: boolean;
        referralCode: any;
        firstName: any;
        totalReferrals: number;
        completedReferrals: number;
        signedUpReferrals: number;
        pendingReferrals: number;
        totalVisits: number;
        tier: string;
        rewards: {
            name: string;
            unlocked: boolean;
            at?: number;
        }[];
        clicks: number;
        registered: number;
        successful: number;
        totalEarned: number;
    }>;
}
