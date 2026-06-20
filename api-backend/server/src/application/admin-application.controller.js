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
exports.AdminApplicationController = void 0;
const common_1 = require("@nestjs/common");
const admin_application_service_1 = require("./admin-application.service");
const staff_guard_1 = require("../auth/staff.guard");
let AdminApplicationController = class AdminApplicationController {
    adminApplicationService;
    constructor(adminApplicationService) {
        this.adminApplicationService = adminApplicationService;
    }
    async addRemark(appId, body, req) {
        return await this.adminApplicationService.addRemark(appId, {
            applicationId: appId,
            type: body.type,
            content: body.content,
            authorId: req.user.id,
            authorName: req.user.firstName,
            isInternal: true,
        });
    }
    async getRemarks(appId) {
        const remarks = await this.adminApplicationService.getApplicationRemarks(appId);
        return { success: true, data: remarks };
    }
    async assignMentorCounselor(appId, body, req) {
        return await this.adminApplicationService.assignMentorCounselor({
            applicationId: appId,
            mentorId: body.mentorId,
            mentorName: body.mentorName,
            counselorId: body.counselorId,
            counselorName: body.counselorName,
        });
    }
    async assessRisk(appId, body) {
        return await this.adminApplicationService.assessRisk({
            applicationId: appId,
            riskLevel: body.riskLevel,
            creditScore: body.creditScore,
            notes: body.notes,
        });
    }
    async batchProcessApplications(body, req) {
        return await this.adminApplicationService.batchProcessApplications(body.applicationIds, body.action, body.remarks, req.user.id, req.user.firstName);
    }
    async checkEligibility(appId) {
        const assessment = await this.adminApplicationService.checkEligibility(appId);
        return { success: true, data: assessment };
    }
    async getPortfolioAnalysis(req) {
        const bankId = req.query.bankId;
        const analysis = await this.adminApplicationService.getPortfolioAnalysis(req.user, bankId);
        return { success: true, data: analysis };
    }
    async getComplianceReport(req) {
        const bankId = req.query.bankId;
        const report = await this.adminApplicationService.getComplianceReport(req.user, bankId);
        return { success: true, data: report };
    }
};
exports.AdminApplicationController = AdminApplicationController;
__decorate([
    (0, common_1.Post)(':id/remarks'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "addRemark", null);
__decorate([
    (0, common_1.Get)(':id/remarks'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "getRemarks", null);
__decorate([
    (0, common_1.Put)(':id/assign-mentor'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "assignMentorCounselor", null);
__decorate([
    (0, common_1.Put)(':id/risk-assessment'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "assessRisk", null);
__decorate([
    (0, common_1.Post)('batch-process'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "batchProcessApplications", null);
__decorate([
    (0, common_1.Get)(':id/eligibility'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "checkEligibility", null);
__decorate([
    (0, common_1.Get)('portfolio/analysis'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "getPortfolioAnalysis", null);
__decorate([
    (0, common_1.Get)('compliance/report'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminApplicationController.prototype, "getComplianceReport", null);
exports.AdminApplicationController = AdminApplicationController = __decorate([
    (0, common_1.Controller)('admin/applications'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __metadata("design:paramtypes", [admin_application_service_1.AdminApplicationService])
], AdminApplicationController);
//# sourceMappingURL=admin-application.controller.js.map