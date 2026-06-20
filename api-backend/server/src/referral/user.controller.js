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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserController = void 0;
const common_1 = require("@nestjs/common");
const referral_service_1 = require("./referral.service");
const user_guard_1 = require("../auth/user.guard");
let UserController = class UserController {
    referralService;
    constructor(referralService) {
        this.referralService = referralService;
    }
    async getReferralStats(req) {
        try {
            const userId = req.user?.sub || req.user?.id;
            if (!userId) {
                throw new common_1.HttpException('Unauthorized', common_1.HttpStatus.UNAUTHORIZED);
            }
            const stats = await this.referralService.getReferralStats(userId);
            return {
                success: true,
                referralCode: stats.referralCode,
                firstName: stats.firstName,
                totalReferrals: stats.totalReferrals,
                completedReferrals: stats.completedReferrals,
                signedUpReferrals: stats.signedUpReferrals,
                pendingReferrals: stats.pendingReferrals,
                totalVisits: stats.totalVisits,
                tier: stats.tier,
                rewards: stats.rewards,
                clicks: stats.totalVisits,
                registered: stats.signedUpReferrals,
                successful: stats.completedReferrals,
                totalEarned: stats.completedReferrals * 3000,
            };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to get referral stats', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
};
exports.UserController = UserController;
__decorate([
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    (0, common_1.Get)('referral-stats'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UserController.prototype, "getReferralStats", null);
exports.UserController = UserController = __decorate([
    (0, common_1.Controller)('user'),
    __metadata("design:paramtypes", [referral_service_1.ReferralService])
], UserController);
//# sourceMappingURL=user.controller.js.map