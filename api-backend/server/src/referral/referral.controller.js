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
exports.ReferralController = void 0;
const common_1 = require("@nestjs/common");
const referral_service_1 = require("./referral.service");
const user_guard_1 = require("../auth/user.guard");
let ReferralController = class ReferralController {
    referralService;
    constructor(referralService) {
        this.referralService = referralService;
    }
    async getMyCode(req) {
        try {
            const userId = req.user?.sub || req.user?.id;
            if (!userId) {
                throw new common_1.HttpException('Unauthorized', common_1.HttpStatus.UNAUTHORIZED);
            }
            const result = await this.referralService.getOrCreateReferralCode(userId);
            return { success: true, ...result };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to get referral code', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getStats(req) {
        try {
            const userId = req.user?.sub || req.user?.id;
            if (!userId) {
                throw new common_1.HttpException('Unauthorized', common_1.HttpStatus.UNAUTHORIZED);
            }
            const stats = await this.referralService.getReferralStats(userId);
            return { success: true, ...stats };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to get referral stats', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getReferralList(req) {
        try {
            const userId = req.user?.sub || req.user?.id;
            if (!userId) {
                throw new common_1.HttpException('Unauthorized', common_1.HttpStatus.UNAUTHORIZED);
            }
            const referrals = await this.referralService.getReferralList(userId);
            return { success: true, referrals };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to get referral list', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async validateCode(code) {
        try {
            const result = await this.referralService.validateReferralCode(code);
            return { success: true, ...result };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to validate referral code', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async recordReferral(body) {
        if (!body || !body.referralCode || !body.refereeEmail) {
            return {
                success: false,
                message: 'Referral code and referee email are required',
            };
        }
        try {
            const result = await this.referralService.recordReferral(body.referralCode, body.refereeEmail, body.refereeId);
            return { success: true, referral: result };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to record referral', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async sendInvite(req, body) {
        if (!body || !body.email) {
            return {
                success: false,
                message: 'Email is required',
            };
        }
        try {
            const userId = req.user?.sub || req.user?.id;
            if (!userId) {
                throw new common_1.HttpException('Unauthorized', common_1.HttpStatus.UNAUTHORIZED);
            }
            const referral = await this.referralService.sendInvite(userId, body.email);
            return { success: true, referral };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to send invite', error.message?.includes('already') ? common_1.HttpStatus.CONFLICT : common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getLeaderboard(limit) {
        try {
            const leaderboard = await this.referralService.getLeaderboard(limit ? parseInt(limit, 10) : 10);
            return { success: true, leaderboard };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to get leaderboard', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async recordVisit(code, req) {
        try {
            const ip = req.ip || req.headers['x-forwarded-for'] || req.connection.remoteAddress;
            const userAgent = req.headers['user-agent'];
            await this.referralService.recordVisit(code, ip, userAgent);
            return { success: true };
        }
        catch (error) {
            return { success: false, message: error.message };
        }
    }
};
exports.ReferralController = ReferralController;
__decorate([
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    (0, common_1.Get)('my-code'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "getMyCode", null);
__decorate([
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    (0, common_1.Get)('stats'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "getStats", null);
__decorate([
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    (0, common_1.Get)('list'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "getReferralList", null);
__decorate([
    (0, common_1.Get)('validate/:code'),
    __param(0, (0, common_1.Param)('code')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "validateCode", null);
__decorate([
    (0, common_1.Post)('record'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "recordReferral", null);
__decorate([
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    (0, common_1.Post)('invite'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "sendInvite", null);
__decorate([
    (0, common_1.Get)('leaderboard'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "getLeaderboard", null);
__decorate([
    (0, common_1.Post)('visit/:code'),
    __param(0, (0, common_1.Param)('code')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], ReferralController.prototype, "recordVisit", null);
exports.ReferralController = ReferralController = __decorate([
    (0, common_1.Controller)('referral'),
    __metadata("design:paramtypes", [referral_service_1.ReferralService])
], ReferralController);
//# sourceMappingURL=referral.controller.js.map