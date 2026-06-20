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
exports.BankFeaturesController = void 0;
const common_1 = require("@nestjs/common");
const staff_guard_1 = require("../auth/staff.guard");
const bank_features_dto_1 = require("./dto/bank-features.dto");
let BankFeaturesController = class BankFeaturesController {
    async getSchemes(bank, active = true) {
        throw new Error('Not implemented');
    }
    async getScheme(schemeId) {
        throw new Error('Not implemented');
    }
    async createScheme(dto, req) {
        throw new Error('Not implemented');
    }
    async updateScheme(schemeId, dto, req) {
        throw new Error('Not implemented');
    }
    async deleteScheme(schemeId, req) {
        throw new Error('Not implemented');
    }
    async getExpiringSchemes(daysUntilExpiry = 30) {
        throw new Error('Not implemented');
    }
    async getAssignmentRules() {
        throw new Error('Not implemented');
    }
    async createAssignmentRule(dto, req) {
        throw new Error('Not implemented');
    }
    async updateAssignmentRule(ruleId, dto, req) {
        throw new Error('Not implemented');
    }
    async deleteAssignmentRule(ruleId, req) {
        throw new Error('Not implemented');
    }
    async triggerAutoAssignment(req, limit) {
        throw new Error('Not implemented');
    }
    async getAssignmentLogs(applicationId, limit = 100) {
        throw new Error('Not implemented');
    }
    async createOfficerTarget(dto, req) {
        throw new Error('Not implemented');
    }
    async getOfficerTarget(targetId) {
        throw new Error('Not implemented');
    }
    async updateOfficerTarget(targetId, dto, req) {
        throw new Error('Not implemented');
    }
    async getMonthlyTargets(month, officerId) {
        throw new Error('Not implemented');
    }
    async getOfficerAchievements(officerId, month) {
        throw new Error('Not implemented');
    }
    async createRMProfile(dto, req) {
        throw new Error('Not implemented');
    }
    async getRMProfile(profileId) {
        throw new Error('Not implemented');
    }
    async updateRMProfile(profileId, dto, req) {
        throw new Error('Not implemented');
    }
    async requestExport(dto, req) {
        throw new Error('Not implemented');
    }
    async getExportJobStatus(jobId) {
        throw new Error('Not implemented');
    }
    async downloadExportFile(jobId, req) {
        throw new Error('Not implemented');
    }
    async getColumnPreferences(req) {
        throw new Error('Not implemented');
    }
    async saveColumnPreferences(dto, req) {
        throw new Error('Not implemented');
    }
    async getBranchStatistics(branchCode, startDate, endDate) {
        throw new Error('Not implemented');
    }
    async getMultibranchReport(startDate, endDate) {
        throw new Error('Not implemented');
    }
    async createScheduledReport(dto, req) {
        throw new Error('Not implemented');
    }
    async getScheduledReports() {
        throw new Error('Not implemented');
    }
    async updateScheduledReport(reportId, dto, req) {
        throw new Error('Not implemented');
    }
    async triggerReportGeneration(reportId, req) {
        throw new Error('Not implemented');
    }
    async getReportHistory(limit = 50) {
        throw new Error('Not implemented');
    }
    async createStudentRating(dto, req) {
        throw new Error('Not implemented');
    }
    async getStudentRatings(studentId) {
        throw new Error('Not implemented');
    }
    async getProductConfigs(bankId) {
        throw new Error('Not implemented');
    }
    async createProductConfig(dto, req) {
        throw new Error('Not implemented');
    }
    async updateProductConfig(configId, dto, req) {
        throw new Error('Not implemented');
    }
    async getChecklistConfigs(bankId, productType) {
        throw new Error('Not implemented');
    }
    async createChecklistConfig(dto, req) {
        throw new Error('Not implemented');
    }
    async updateChecklistConfig(configId, dto, req) {
        throw new Error('Not implemented');
    }
    async getBranchConfigs(bankId) {
        throw new Error('Not implemented');
    }
    async getBranchConfig(branchCode) {
        throw new Error('Not implemented');
    }
    async createBranchConfig(dto, req) {
        throw new Error('Not implemented');
    }
    async updateBranchConfig(configId, dto, req) {
        throw new Error('Not implemented');
    }
};
exports.BankFeaturesController = BankFeaturesController;
__decorate([
    (0, common_1.Get)('schemes'),
    __param(0, (0, common_1.Query)('bank')),
    __param(1, (0, common_1.Query)('active')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Boolean]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getSchemes", null);
__decorate([
    (0, common_1.Get)('schemes/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getScheme", null);
__decorate([
    (0, common_1.Post)('schemes'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateBankSchemeDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createScheme", null);
__decorate([
    (0, common_1.Put)('schemes/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateScheme", null);
__decorate([
    (0, common_1.Delete)('schemes/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "deleteScheme", null);
__decorate([
    (0, common_1.Get)('schemes/expiring'),
    __param(0, (0, common_1.Query)('days')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getExpiringSchemes", null);
__decorate([
    (0, common_1.Get)('assignment-rules'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getAssignmentRules", null);
__decorate([
    (0, common_1.Post)('assignment-rules'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateAssignmentRuleDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createAssignmentRule", null);
__decorate([
    (0, common_1.Put)('assignment-rules/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateAssignmentRule", null);
__decorate([
    (0, common_1.Delete)('assignment-rules/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "deleteAssignmentRule", null);
__decorate([
    (0, common_1.Post)('auto-assign'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Number]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "triggerAutoAssignment", null);
__decorate([
    (0, common_1.Get)('assignment-logs'),
    __param(0, (0, common_1.Query)('applicationId')),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Number]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getAssignmentLogs", null);
__decorate([
    (0, common_1.Post)('officer-targets'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateOfficerTargetDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createOfficerTarget", null);
__decorate([
    (0, common_1.Get)('officer-targets/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getOfficerTarget", null);
__decorate([
    (0, common_1.Put)('officer-targets/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateOfficerTarget", null);
__decorate([
    (0, common_1.Get)('officer-targets/month/:month'),
    __param(0, (0, common_1.Param)('month')),
    __param(1, (0, common_1.Query)('officerId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getMonthlyTargets", null);
__decorate([
    (0, common_1.Get)('officer-achievements/:officerId'),
    __param(0, (0, common_1.Param)('officerId')),
    __param(1, (0, common_1.Query)('month')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getOfficerAchievements", null);
__decorate([
    (0, common_1.Post)('rm-profiles'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateRMProfileDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createRMProfile", null);
__decorate([
    (0, common_1.Get)('rm-profiles/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getRMProfile", null);
__decorate([
    (0, common_1.Put)('rm-profiles/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateRMProfile", null);
__decorate([
    (0, common_1.Post)('export/request'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateExportJobDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "requestExport", null);
__decorate([
    (0, common_1.Get)('export/jobs/:jobId'),
    __param(0, (0, common_1.Param)('jobId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getExportJobStatus", null);
__decorate([
    (0, common_1.Get)('export/download/:jobId'),
    __param(0, (0, common_1.Param)('jobId')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "downloadExportFile", null);
__decorate([
    (0, common_1.Get)('export/columns'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getColumnPreferences", null);
__decorate([
    (0, common_1.Post)('export/columns'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "saveColumnPreferences", null);
__decorate([
    (0, common_1.Get)('branches/:branchCode/statistics'),
    __param(0, (0, common_1.Param)('branchCode')),
    __param(1, (0, common_1.Query)('startDate')),
    __param(2, (0, common_1.Query)('endDate')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getBranchStatistics", null);
__decorate([
    (0, common_1.Get)('branches/report/summary'),
    __param(0, (0, common_1.Query)('startDate')),
    __param(1, (0, common_1.Query)('endDate')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getMultibranchReport", null);
__decorate([
    (0, common_1.Post)('reports/schedule'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateScheduledReportDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createScheduledReport", null);
__decorate([
    (0, common_1.Get)('reports/schedules'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getScheduledReports", null);
__decorate([
    (0, common_1.Put)('reports/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateScheduledReport", null);
__decorate([
    (0, common_1.Post)('reports/run'),
    __param(0, (0, common_1.Query)('reportId')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "triggerReportGeneration", null);
__decorate([
    (0, common_1.Get)('reports/history'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getReportHistory", null);
__decorate([
    (0, common_1.Post)('student-ratings'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateStudentRatingDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createStudentRating", null);
__decorate([
    (0, common_1.Get)('student-ratings/:studentId'),
    __param(0, (0, common_1.Param)('studentId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getStudentRatings", null);
__decorate([
    (0, common_1.Get)('config/products'),
    __param(0, (0, common_1.Query)('bankId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getProductConfigs", null);
__decorate([
    (0, common_1.Post)('config/products'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateProductConfigDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createProductConfig", null);
__decorate([
    (0, common_1.Put)('config/products/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateProductConfig", null);
__decorate([
    (0, common_1.Get)('config/checklists'),
    __param(0, (0, common_1.Query)('bankId')),
    __param(1, (0, common_1.Query)('productType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getChecklistConfigs", null);
__decorate([
    (0, common_1.Post)('config/checklists'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateChecklistConfigDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createChecklistConfig", null);
__decorate([
    (0, common_1.Put)('config/checklists/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateChecklistConfig", null);
__decorate([
    (0, common_1.Get)('config/branches'),
    __param(0, (0, common_1.Query)('bankId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getBranchConfigs", null);
__decorate([
    (0, common_1.Get)('config/branches/:branchCode'),
    __param(0, (0, common_1.Param)('branchCode')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "getBranchConfig", null);
__decorate([
    (0, common_1.Post)('config/branches'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [bank_features_dto_1.CreateBranchConfigDto, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "createBranchConfig", null);
__decorate([
    (0, common_1.Put)('config/branches/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, Object]),
    __metadata("design:returntype", Promise)
], BankFeaturesController.prototype, "updateBranchConfig", null);
exports.BankFeaturesController = BankFeaturesController = __decorate([
    (0, common_1.Controller)('bank'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard)
], BankFeaturesController);
//# sourceMappingURL=bank-features.controller.js.map