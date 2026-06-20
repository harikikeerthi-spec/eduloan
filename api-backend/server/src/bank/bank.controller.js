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
exports.BankController = void 0;
const common_1 = require("@nestjs/common");
const staff_guard_1 = require("../auth/staff.guard");
const bank_rbac_middleware_1 = require("./bank-rbac.middleware");
const bank_service_1 = require("./bank.service");
let BankController = class BankController {
    bankService;
    constructor(bankService) {
        this.bankService = bankService;
    }
    resolveBankName(req) {
        const headerBank = req.headers['x-selected-bank'];
        if (headerBank)
            return headerBank.toString();
        if (req.user?.role === 'bank') {
            return req.user.firstName || 'SBI';
        }
        return '';
    }
    async getIncomingFiles(req, limit, offset) {
        const bankName = this.resolveBankName(req);
        return this.bankService.getIncomingFiles(bankName, { limit, offset });
    }
    async logFile(req, id, lanNumber) {
        return this.bankService.logFile(id, lanNumber, req.user);
    }
    async getDocuments(applicationId) {
        return this.bankService.getDocuments(applicationId);
    }
    async downloadDocumentsZip(applicationId, res) {
        const zipData = await this.bankService.generateDocumentsZip(applicationId);
        res.setHeader('Content-Disposition', `attachment; filename=${zipData.fileName}`);
        res.status(common_1.HttpStatus.OK).send(zipData.buffer);
    }
    async submitDecision(req, applicationId, decisionType, details) {
        return this.bankService.registerDecision(applicationId, decisionType, details, req.user);
    }
    async raiseQuery(req, applicationId, content) {
        return this.bankService.raiseQuery(applicationId, content, req.user);
    }
    async confirmDisbursement(req, applicationId, disbursementAmount, trancheNumber, transferMode, utrNumber) {
        return this.bankService.confirmDisbursement(applicationId, disbursementAmount, trancheNumber, transferMode, utrNumber, req.user);
    }
    async conditionalSanction(req, applicationId, conditions, deadline) {
        return this.bankService.registerDecision(applicationId, 'conditional_sanction', { conditions, deadline }, req.user);
    }
    async partialSanction(req, applicationId, sanctionAmount, shortfallAmount, reason) {
        return this.bankService.registerDecision(applicationId, 'sanction_approved', { sanctionAmount, shortfallAmount, reason }, req.user);
    }
    async counterOffer(req, applicationId, offeredAmount, offeredRate, offeredTenure) {
        return this.bankService.registerDecision(applicationId, 'counter_offer', { offeredAmount, offeredRate, offeredTenure }, req.user);
    }
    async fileQualityScore(applicationId, rating, feedback) {
        return this.bankService.submitFileQualityScore(applicationId, rating, feedback);
    }
    async getChannelAnalytics(req) {
        const bankName = this.resolveBankName(req);
        return {
            success: true,
            bank: bankName,
            roiSpreads: [
                { product: 'Scholar Loan', rate: 9.25, type: 'Floating' },
                { product: 'Student Prime', rate: 10.50, type: 'Fixed' }
            ],
            rejectionsByCause: [
                { cause: 'CIBIL Score Shortfall', count: 18 },
                { cause: 'Collateral Value Insufficient', count: 9 }
            ]
        };
    }
    async getRejectionAnalytics(req) {
        const bankName = this.resolveBankName(req);
        return {
            success: true,
            bank: bankName,
            totalRejections: 27,
            causes: [
                { label: 'Credit Score', count: 12 },
                { label: 'Program Ineligible', count: 15 }
            ]
        };
    }
    async getSlaTracker(req) {
        const bankName = this.resolveBankName(req);
        return this.bankService.getSlaTrackingMetrics(bankName);
    }
    async getLoanProducts(req) {
        const bankName = this.resolveBankName(req);
        return this.bankService.getProducts(bankName);
    }
    async createLoanProduct(body) {
        return this.bankService.createProduct(body);
    }
    async updateLoanProduct(id, body) {
        return this.bankService.updateProduct(id, body);
    }
    async getBranches(req) {
        const bankName = this.resolveBankName(req);
        return this.bankService.getBranches(bankName);
    }
    async createBranch(body) {
        return this.bankService.createBranch(body);
    }
    async getOfficers(req) {
        const bankName = this.resolveBankName(req);
        return this.bankService.getOfficers(bankName);
    }
    async getFileDetail(id) {
        return this.bankService.getFileDetail(id);
    }
    async lookupByLan(lan) {
        return this.bankService.lookupByLan(lan);
    }
    async getMyFiles(req, filters) {
        const bankName = this.resolveBankName(req);
        return this.bankService.getMyFiles(bankName, filters);
    }
    async amendDecision(decisionId, applicationId, details, req) {
        return this.bankService.amendDecision(applicationId, decisionId, details, req.user);
    }
    async uploadSanctionLetter(id, fileUrl, req) {
        return this.bankService.uploadSanctionLetter(id, fileUrl, req.user);
    }
    async setRoi(id, roiData, req) {
        return this.bankService.setRoi(id, roiData, req.user);
    }
    async setProcessingFee(id, feeData) {
        return this.bankService.setProcessingFee(id, feeData);
    }
    async updateProcessingFee(id, updateData) {
        return this.bankService.updateProcessingFee(id, updateData);
    }
    async getQueryThread(queryId) {
        return this.bankService.getQueryThread(queryId);
    }
    async resolveQuery(queryId) {
        return this.bankService.resolveQuery(queryId);
    }
    async getAnalyticsMetrics(req) {
        const bankName = this.resolveBankName(req);
        return this.bankService.getAnalyticsMetrics(bankName);
    }
    async exportApplicationsCsv(req) {
        const bankName = this.resolveBankName(req);
        return this.bankService.exportApplicationsCsv(bankName);
    }
    async exportMisReports(req) {
        const bankName = this.resolveBankName(req);
        return this.bankService.exportMisReports(bankName);
    }
};
exports.BankController = BankController;
__decorate([
    (0, common_1.Get)('incoming-files'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getIncomingFiles", null);
__decorate([
    (0, common_1.Post)('files/:id/log'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)('lanNumber')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "logFile", null);
__decorate([
    (0, common_1.Get)('documents/:applicationId'),
    __param(0, (0, common_1.Param)('applicationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getDocuments", null);
__decorate([
    (0, common_1.Get)('documents/:applicationId/zip'),
    (0, common_1.Header)('Content-Type', 'application/zip'),
    __param(0, (0, common_1.Param)('applicationId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "downloadDocumentsZip", null);
__decorate([
    (0, common_1.Post)('decisions'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('applicationId')),
    __param(2, (0, common_1.Body)('decisionType')),
    __param(3, (0, common_1.Body)('details')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "submitDecision", null);
__decorate([
    (0, common_1.Post)('queries'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('applicationId')),
    __param(2, (0, common_1.Body)('content')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "raiseQuery", null);
__decorate([
    (0, common_1.Post)('disbursements/confirm'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('applicationId')),
    __param(2, (0, common_1.Body)('disbursementAmount')),
    __param(3, (0, common_1.Body)('trancheNumber')),
    __param(4, (0, common_1.Body)('transferMode')),
    __param(5, (0, common_1.Body)('utrNumber')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Number, Number, String, String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "confirmDisbursement", null);
__decorate([
    (0, common_1.Post)('conditional-sanctions'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('applicationId')),
    __param(2, (0, common_1.Body)('conditions')),
    __param(3, (0, common_1.Body)('deadline')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Array, String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "conditionalSanction", null);
__decorate([
    (0, common_1.Post)('partial-sanctions'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('applicationId')),
    __param(2, (0, common_1.Body)('sanctionAmount')),
    __param(3, (0, common_1.Body)('shortfallAmount')),
    __param(4, (0, common_1.Body)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Number, Number, String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "partialSanction", null);
__decorate([
    (0, common_1.Post)('counter-offers'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('applicationId')),
    __param(2, (0, common_1.Body)('offeredAmount')),
    __param(3, (0, common_1.Body)('offeredRate')),
    __param(4, (0, common_1.Body)('offeredTenure')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Number, Number, Number]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "counterOffer", null);
__decorate([
    (0, common_1.Post)('file-quality-score'),
    __param(0, (0, common_1.Body)('applicationId')),
    __param(1, (0, common_1.Body)('rating')),
    __param(2, (0, common_1.Body)('feedback')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Number, String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "fileQualityScore", null);
__decorate([
    (0, common_1.Get)('analytics/channel'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getChannelAnalytics", null);
__decorate([
    (0, common_1.Get)('analytics/rejections'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getRejectionAnalytics", null);
__decorate([
    (0, common_1.Get)('sla-tracker'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getSlaTracker", null);
__decorate([
    (0, common_1.Get)('config/loan-products'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getLoanProducts", null);
__decorate([
    (0, common_1.Post)('config/loan-products'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "createLoanProduct", null);
__decorate([
    (0, common_1.Put)('config/loan-products/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "updateLoanProduct", null);
__decorate([
    (0, common_1.Get)('config/branches'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getBranches", null);
__decorate([
    (0, common_1.Post)('config/branches'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "createBranch", null);
__decorate([
    (0, common_1.Get)('config/officers'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getOfficers", null);
__decorate([
    (0, common_1.Get)('applications/:id/detail'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getFileDetail", null);
__decorate([
    (0, common_1.Get)('lookup/:lan'),
    __param(0, (0, common_1.Param)('lan')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "lookupByLan", null);
__decorate([
    (0, common_1.Get)('my-files'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getMyFiles", null);
__decorate([
    (0, common_1.Put)('decisions/:decisionId'),
    __param(0, (0, common_1.Param)('decisionId')),
    __param(1, (0, common_1.Body)('applicationId')),
    __param(2, (0, common_1.Body)('details')),
    __param(3, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "amendDecision", null);
__decorate([
    (0, common_1.Post)('applications/:id/sanction-letter'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)('fileUrl')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "uploadSanctionLetter", null);
__decorate([
    (0, common_1.Post)('applications/:id/roi'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "setRoi", null);
__decorate([
    (0, common_1.Post)('applications/:id/fee'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "setProcessingFee", null);
__decorate([
    (0, common_1.Put)('applications/:id/fee'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "updateProcessingFee", null);
__decorate([
    (0, common_1.Get)('queries/:queryId'),
    __param(0, (0, common_1.Param)('queryId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getQueryThread", null);
__decorate([
    (0, common_1.Post)('queries/:queryId/resolve'),
    __param(0, (0, common_1.Param)('queryId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "resolveQuery", null);
__decorate([
    (0, common_1.Get)('analytics/metrics'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "getAnalyticsMetrics", null);
__decorate([
    (0, common_1.Get)('export/csv'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "exportApplicationsCsv", null);
__decorate([
    (0, common_1.Get)('export/mis'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankController.prototype, "exportMisReports", null);
exports.BankController = BankController = __decorate([
    (0, common_1.Controller)('bank'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    (0, common_1.UseInterceptors)(bank_rbac_middleware_1.BankRbacInterceptor),
    __metadata("design:paramtypes", [bank_service_1.BankService])
], BankController);
//# sourceMappingURL=bank.controller.js.map