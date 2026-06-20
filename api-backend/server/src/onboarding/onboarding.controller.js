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
exports.OnboardingController = void 0;
const common_1 = require("@nestjs/common");
const onboarding_service_1 = require("./onboarding.service");
const user_guard_1 = require("../auth/user.guard");
let OnboardingController = class OnboardingController {
    onboardingService;
    constructor(onboardingService) {
        this.onboardingService = onboardingService;
    }
    async saveOnboardingData(body, req) {
        const isAdminOrStaff = req.user && ['admin', 'super_admin', 'staff'].includes(req.user.role);
        let targetUserId = req.user.id;
        if (isAdminOrStaff && body.userId) {
            targetUserId = body.userId;
        }
        else if (isAdminOrStaff && body.email) {
            targetUserId = undefined;
        }
        return this.onboardingService.saveOnboardingData(body, targetUserId);
    }
    async getStatus(req) {
        const user = req.user;
        const keysToCheck = [
            'goal', 'studyDestination', 'courseName', 'bachelorsDegree', 'gpa', 'workExp'
        ];
        const isCompleted = keysToCheck.every(k => !!user[k]);
        return {
            success: true,
            isCompleted,
            user
        };
    }
    async shareOnboardingLink(body, req) {
        const { studentId, studentEmail, studentName, shareUrl } = body;
        if (!studentId || !studentEmail || !studentName || !shareUrl) {
            return { success: false, message: 'Missing required parameters: studentId, studentEmail, studentName, shareUrl' };
        }
        return this.onboardingService.shareOnboardingLink(studentId, studentEmail, studentName, shareUrl, req.user);
    }
};
exports.OnboardingController = OnboardingController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], OnboardingController.prototype, "saveOnboardingData", null);
__decorate([
    (0, common_1.Get)('status'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OnboardingController.prototype, "getStatus", null);
__decorate([
    (0, common_1.Post)('share'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], OnboardingController.prototype, "shareOnboardingLink", null);
exports.OnboardingController = OnboardingController = __decorate([
    (0, common_1.Controller)('onboarding'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __metadata("design:paramtypes", [onboarding_service_1.OnboardingService])
], OnboardingController);
//# sourceMappingURL=onboarding.controller.js.map