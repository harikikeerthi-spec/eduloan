"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReferralService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const event_emitter_1 = require("@nestjs/event-emitter");
let ReferralService = class ReferralService {
    supabase;
    logger = { warn: (m) => console.warn(m) };
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase) {
        this.supabase = supabase;
    }
    async handleApplicationDisbursed(event) {
        if (event.userId) {
            try {
                await this.completeReferral(event.userId);
            }
            catch (error) {
                console.error(`[ReferralService] Failed to process application disbursed event for user: ${event.userId}`, error);
            }
        }
    }
    generateCode() {
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        let code = 'VL-';
        for (let i = 0; i < 6; i++) {
            code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return code;
    }
    async getOrCreateReferralCode(userId) {
        const { data: user } = await this.db
            .from('User')
            .select('id, referralCode, firstName, lastName, email')
            .eq('id', userId)
            .single();
        if (!user)
            throw new Error('User not found');
        if (user.referralCode)
            return { referralCode: user.referralCode, user };
        let code = '';
        let exists = true;
        while (exists) {
            code = this.generateCode();
            const { data: existing } = await this.db.from('User').select('id').eq('referralCode', code).single();
            exists = !!existing;
        }
        const { data: updated, error } = await this.db
            .from('User')
            .update({ referralCode: code })
            .eq('id', userId)
            .select('id, referralCode, firstName, lastName, email')
            .single();
        if (error)
            throw error;
        return { referralCode: updated.referralCode, user: updated };
    }
    async getReferralStats(userId) {
        const { data: user } = await this.db
            .from('User')
            .select('referralCode, firstName')
            .eq('id', userId)
            .single();
        const [{ count: totalReferrals }, { count: completedReferrals }, { count: signedUpReferrals }, { count: pendingReferrals }, { count: totalVisits },] = await Promise.all([
            this.db.from('Referral').select('*', { count: 'exact', head: true }).eq('referrerId', userId),
            this.db.from('Referral').select('*', { count: 'exact', head: true }).eq('referrerId', userId).eq('status', 'completed'),
            this.db.from('Referral').select('*', { count: 'exact', head: true }).eq('referrerId', userId).eq('status', 'signed_up'),
            this.db.from('Referral').select('*', { count: 'exact', head: true }).eq('referrerId', userId).eq('status', 'pending'),
            this.db.from('ReferralVisit').select('*', { count: 'exact', head: true }).eq('referrerId', userId),
        ]);
        const completedCount = completedReferrals || 0;
        let tier = 'starter';
        let nextTierAt = 3;
        if (completedCount >= 10) {
            tier = 'diamond';
            nextTierAt = null;
        }
        else if (completedCount >= 7) {
            tier = 'gold';
            nextTierAt = 10;
        }
        else if (completedCount >= 5) {
            tier = 'silver';
            nextTierAt = 7;
        }
        else if (completedCount >= 3) {
            tier = 'bronze';
            nextTierAt = 5;
        }
        const rewards = this.calculateRewards(completedCount);
        return {
            referralCode: user?.referralCode,
            firstName: user?.firstName,
            totalReferrals: totalReferrals || 0,
            completedReferrals: completedCount,
            signedUpReferrals: signedUpReferrals || 0,
            pendingReferrals: pendingReferrals || 0,
            totalVisits: totalVisits || 0,
            tier,
            nextTierAt,
            rewards,
        };
    }
    async getReferralList(userId) {
        const { data: referrals } = await this.db
            .from('Referral')
            .select('*, referee:User!refereeId(firstName, lastName, email)')
            .eq('referrerId', userId)
            .order('createdAt', { ascending: false });
        return (referrals || []).map((r) => ({
            id: r.id,
            refereeEmail: r.refereeEmail || r.referee?.email,
            refereeName: r.referee ? `${r.referee.firstName || ''} ${r.referee.lastName || ''}`.trim() : null,
            status: r.status,
            reward: r.reward,
            createdAt: r.createdAt,
            completedAt: r.completedAt,
        }));
    }
    async validateReferralCode(code) {
        const { data: user } = await this.db
            .from('User')
            .select('id, firstName, lastName')
            .eq('referralCode', code.toUpperCase().trim())
            .single();
        if (!user)
            return { valid: false };
        return {
            valid: true,
            referrerName: `${user.firstName || ''} ${user.lastName || ''}`.trim() || 'A friend',
        };
    }
    async recordReferral(referralCode, refereeEmail, refereeId) {
        const { data: referrer } = await this.db
            .from('User')
            .select('*')
            .eq('referralCode', referralCode.toUpperCase().trim())
            .single();
        if (!referrer) {
            this.logger.warn(`Invalid referral code used: ${referralCode}`);
            return null;
        }
        const { data: existing } = await this.db
            .from('Referral')
            .select('id')
            .eq('referrerId', referrer.id)
            .eq('refereeEmail', refereeEmail)
            .single();
        if (existing) {
            const { data, error } = await this.db
                .from('Referral')
                .update({ refereeId, status: refereeId ? 'signed_up' : 'pending' })
                .eq('id', existing.id)
                .select()
                .single();
            if (error)
                throw error;
            return data;
        }
        const { data: referral, error } = await this.db
            .from('Referral')
            .insert({ referrerId: referrer.id, refereeEmail, refereeId, status: refereeId ? 'signed_up' : 'pending' })
            .select()
            .single();
        if (error)
            throw error;
        if (refereeId) {
            await this.db.from('User').update({ referredById: referrer.id }).eq('id', refereeId);
        }
        return referral;
    }
    async completeReferral(refereeId) {
        const { data: referral } = await this.db
            .from('Referral')
            .select('*')
            .eq('refereeId', refereeId)
            .single();
        if (!referral || referral.status === 'completed')
            return null;
        const { count: completedCount } = await this.db
            .from('Referral')
            .select('*', { count: 'exact', head: true })
            .eq('referrerId', referral.referrerId)
            .eq('status', 'completed');
        const newCompletedCount = (completedCount || 0) + 1;
        let rewardAmount = 3000;
        if (newCompletedCount === 3)
            rewardAmount += 500;
        else if (newCompletedCount === 5)
            rewardAmount += 10000;
        else if (newCompletedCount === 10)
            rewardAmount += 25000;
        else if (newCompletedCount === 25)
            rewardAmount += 75000;
        else if (newCompletedCount === 50)
            rewardAmount += 200000;
        const rewardStr = `₹${rewardAmount.toLocaleString('en-IN')}`;
        const { data, error } = await this.db
            .from('Referral')
            .update({
            status: 'completed',
            completedAt: new Date().toISOString(),
            reward: rewardStr
        })
            .eq('id', referral.id)
            .select()
            .single();
        if (error)
            throw error;
        const { data: wallet } = await this.db
            .from('wallets')
            .select('balance')
            .eq('user_id', referral.referrerId)
            .single();
        if (!wallet) {
            await this.db
                .from('wallets')
                .insert({ user_id: referral.referrerId, balance: rewardAmount });
        }
        else {
            const newBalance = Number(wallet.balance || 0) + rewardAmount;
            await this.db
                .from('wallets')
                .update({ balance: newBalance, updated_at: new Date().toISOString() })
                .eq('user_id', referral.referrerId);
        }
        return data;
    }
    async sendInvite(userId, email) {
        const { data: user } = await this.db
            .from('User')
            .select('email, referralCode')
            .eq('id', userId)
            .single();
        if (!user)
            throw new Error('User not found');
        if (user.email === email)
            throw new Error('You cannot refer yourself');
        const { data: existing } = await this.db
            .from('Referral')
            .select('id')
            .eq('referrerId', userId)
            .eq('refereeEmail', email)
            .single();
        if (existing)
            throw new Error('You have already invited this person');
        const { data, error } = await this.db
            .from('Referral')
            .insert({ referrerId: userId, refereeEmail: email, status: 'pending' })
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    async getLeaderboard(limit = 10) {
        const { data: referrals } = await this.db
            .from('Referral')
            .select('referrerId')
            .eq('status', 'completed');
        if (!referrals)
            return [];
        const counts = new Map();
        for (const r of referrals) {
            counts.set(r.referrerId, (counts.get(r.referrerId) || 0) + 1);
        }
        const sorted = [...counts.entries()]
            .sort((a, b) => b[1] - a[1])
            .slice(0, limit);
        const leaderboard = await Promise.all(sorted.map(async ([referrerId, count], index) => {
            const { data: user } = await this.db
                .from('User')
                .select('firstName, lastName')
                .eq('id', referrerId)
                .single();
            return {
                rank: index + 1,
                name: user ? `${user.firstName || ''} ${user.lastName?.charAt(0) || ''}.`.trim() : 'Anonymous',
                count,
            };
        }));
        return leaderboard;
    }
    calculateRewards(completedCount) {
        const rewards = [];
        if (completedCount >= 1)
            rewards.push({ name: '₹500 Cashback', unlocked: true });
        else
            rewards.push({ name: '₹500 Cashback', unlocked: false, at: 1 });
        if (completedCount >= 3)
            rewards.push({ name: 'Priority Processing', unlocked: true });
        else
            rewards.push({ name: 'Priority Processing', unlocked: false, at: 3 });
        if (completedCount >= 5)
            rewards.push({ name: '0.25% Rate Discount', unlocked: true });
        else
            rewards.push({ name: '0.25% Rate Discount', unlocked: false, at: 5 });
        if (completedCount >= 7)
            rewards.push({ name: 'Premium Support', unlocked: true });
        else
            rewards.push({ name: 'Premium Support', unlocked: false, at: 7 });
        if (completedCount >= 10)
            rewards.push({ name: 'Diamond Status + ₹5000', unlocked: true });
        else
            rewards.push({ name: 'Diamond Status + ₹5000', unlocked: false, at: 10 });
        return rewards;
    }
    getRewardForCount(count) {
        if (count >= 10)
            return 'diamond';
        if (count >= 7)
            return 'gold';
        if (count >= 5)
            return 'silver';
        if (count >= 3)
            return 'bronze';
        return 'none';
    }
    async recordVisit(code, ipAddress, userAgent) {
        const { data: referrer } = await this.db
            .from('User')
            .select('id')
            .eq('referralCode', code.toUpperCase().trim())
            .single();
        const { data } = await this.db.from('ReferralVisit').insert({
            referralCode: code.toUpperCase().trim(),
            ipAddress,
            userAgent,
            referrerId: referrer?.id,
        }).select().single();
        return data;
    }
};
exports.ReferralService = ReferralService;
__decorate([
    (0, event_emitter_1.OnEvent)('bank.application.disbursed'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReferralService.prototype, "handleApplicationDisbursed", null);
exports.ReferralService = ReferralService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], ReferralService);
//# sourceMappingURL=referral.service.js.map