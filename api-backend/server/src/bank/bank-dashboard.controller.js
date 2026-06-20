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
exports.BankDashboardController = void 0;
const common_1 = require("@nestjs/common");
const staff_guard_1 = require("../auth/staff.guard");
const bank_rbac_middleware_1 = require("./bank-rbac.middleware");
const bank_dashboard_service_1 = require("./bank-dashboard.service");
const supabase_service_1 = require("../supabase/supabase.service");
let BankDashboardController = class BankDashboardController {
    dashboardService;
    supabase;
    constructor(dashboardService, supabase) {
        this.dashboardService = dashboardService;
        this.supabase = supabase;
    }
    async getProducts(req) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getBankProducts(bankId);
    }
    async addProduct(req, body) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.addBankProduct(bankId, body);
    }
    async updateProduct(productId, body) {
        return this.dashboardService.updateBankProduct(productId, body);
    }
    async getBranches(req) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getBankBranches(bankId);
    }
    async addBranch(req, body) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.addBankBranch(bankId, body);
    }
    async createFile(req, body) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.createFileEntry(body.applicationId, bankId, body, req.user);
    }
    async listFiles(req, status, lanNumber, queryBankId) {
        const bankId = queryBankId || this.resolveBankIdOrAll(req);
        return this.dashboardService.listBankFiles(bankId, status, lanNumber);
    }
    async getFile(fileId) {
        return this.dashboardService.getFileDetails(fileId);
    }
    async logFile(req, applicationId, body) {
        return this.dashboardService.logFileWithLAN(applicationId, body.lanNumber, req.user);
    }
    async getFileLog(fileId) {
        return this.dashboardService.getFileLog(fileId);
    }
    async getByLAN(lanNumber) {
        return this.dashboardService.getFilesByLAN(lanNumber);
    }
    async uploadDocuments(req, fileId, body) {
        return this.dashboardService.addDocumentToFile(fileId, body, req.user);
    }
    async getDocuments(fileId) {
        return this.dashboardService.getFileDocuments(fileId);
    }
    async getDocument(fileId, documentId) {
        return this.dashboardService.getDocumentDetails(fileId, documentId);
    }
    async downloadDocuments(fileId) {
        return this.dashboardService.downloadFileAsArchive(fileId);
    }
    async getFileTimeline(applicationId) {
        return this.dashboardService.getFileTimeline(applicationId);
    }
    async getFileEvents(applicationId, type) {
        return this.dashboardService.getFileEvents(applicationId, type);
    }
    async validateLAN(body) {
        return this.dashboardService.validateLANFormat(body.lanNumber);
    }
    async checkLAN(lanNumber) {
        return this.dashboardService.checkLANExists(lanNumber);
    }
    async getLANDetails(lanNumber) {
        return this.dashboardService.getLANDetails(lanNumber);
    }
    async setROI(req, applicationId, body) {
        return this.dashboardService.setROI(applicationId, body, req.user);
    }
    async setProcessingFee(req, applicationId, body) {
        return this.dashboardService.setProcessingFee(applicationId, body, req.user);
    }
    async updateProcessingFee(req, applicationId, body) {
        return this.dashboardService.updateProcessingFeeStatus(applicationId, body.status, body.details);
    }
    async sanctionApplication(req, applicationId, body) {
        return this.dashboardService.sanctionApplication(applicationId, body, req.user);
    }
    async updateSanction(req, applicationId, body) {
        return this.dashboardService.updateSanction(applicationId, body, req.user);
    }
    async recordDecision(req, fileId, body) {
        return this.dashboardService.recordBankDecision(fileId, body, req.user);
    }
    async getAllowedTransitions(req, applicationId) {
        return this.dashboardService.getAllowedTransitionsForApp(applicationId, req.user);
    }
    async transitionStatus(req, applicationId, body) {
        return this.dashboardService.transitionApplicationStatus(applicationId, body.targetStatus, req.user, body.reason);
    }
    async recordBankDecision(req, applicationId, body) {
        return this.dashboardService.recordBankDecision(applicationId, body, req.user);
    }
    async raiseQuery(req, applicationId, body) {
        return this.dashboardService.raiseQuery(applicationId, body, req.user);
    }
    async getQueries(req, applicationId) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getBankQueries(bankId, applicationId);
    }
    async getQuery(queryId) {
        return this.dashboardService.getQueryDetails(queryId);
    }
    async respondToQuery(req, queryId, body) {
        return this.dashboardService.respondToQuery(queryId, body, req.user);
    }
    async getQueryResponses(queryId) {
        return this.dashboardService.getQueryResponses(queryId);
    }
    async resolveQuery(req, queryId, body) {
        return this.dashboardService.resolveQuery(queryId, req.user);
    }
    async recordConsent(req, applicationId, body) {
        return this.dashboardService.recordConsent(applicationId, body, req.user);
    }
    async getConsent(applicationId) {
        return this.dashboardService.getConsentStatus(applicationId);
    }
    async updateReferralFee(req, applicationId, body) {
        return this.dashboardService.updateReferralFee(applicationId, body, req.user);
    }
    async confirmDisbursement(req, applicationId, body) {
        return this.dashboardService.confirmDisbursement(applicationId, body, req.user);
    }
    async getDisbursements(applicationId) {
        return this.dashboardService.getDisbursements(applicationId);
    }
    async getAllDisbursements(req) {
        const bankId = this.resolveBankId(req);
        const { data, error } = await this.supabase.getClient()
            .from('Disbursement')
            .select(`
        *,
        LoanApplication(id, firstName, lastName, amount)
      `)
            .eq('LoanApplication.bank', bankId)
            .order('disbursedAt', { ascending: false });
        return data || [];
    }
    async rateQuality(req, applicationId, body) {
        return this.dashboardService.rateFileQuality(applicationId, body, req.user);
    }
    async getChannelAnalytics(req) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getChannelAnalytics(bankId);
    }
    async getRejectionAnalytics(req) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getRejectionAnalytics(bankId);
    }
    async getPipelineAnalytics(req) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getPipelineAnalytics(bankId);
    }
    async getAgingAnalytics(req) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getAgingReport(bankId);
    }
    async getSLAAnalytics(req) {
        const bankId = this.resolveBankId(req);
        return this.dashboardService.getSLAMetrics(bankId);
    }
    async getAuditLogs(applicationId) {
        return this.dashboardService.getAuditLogs(applicationId);
    }
    async addNote(req, fileId, body) {
        return this.dashboardService.addNote(fileId, body, req.user);
    }
    async getNotes(req, fileId) {
        return this.dashboardService.getNotes(fileId, req.user);
    }
    async updateNote(req, noteId, body) {
        return this.dashboardService.updateNote(noteId, body.content, req.user);
    }
    async deleteNote(req, noteId) {
        await this.dashboardService.deleteNote(noteId, req.user);
    }
    getTagLibrary() {
        return { tags: this.dashboardService.getTagLibrary() };
    }
    async addTag(req, fileId, body) {
        return this.dashboardService.addTag(fileId, body.tag, req.user);
    }
    async removeTag(req, fileId, tag) {
        await this.dashboardService.removeTag(fileId, tag, req.user);
    }
    async getFilesByTag(req, tag) {
        const bankId = this.resolveBankIdOrAll(req);
        return this.dashboardService.getFilesByTag(tag, bankId);
    }
    resolveBankId(req) {
        return this.resolveBankIdOrAll(req) || 'credila';
    }
    resolveBankIdOrAll(req) {
        const headerBank = req.headers['x-bank-id'];
        if (headerBank)
            return headerBank.toString();
        if (req.user?.bankId)
            return req.user.bankId;
        if (req.user?.firstName) {
            const lowerName = req.user.firstName.toLowerCase();
            const validBanks = ['credila', 'auxilo', 'avanse', 'idfc', 'poonawalla', 'sbi', 'icici', 'axis'];
            if (validBanks.includes(lowerName)) {
                return lowerName;
            }
            const matched = validBanks.find(b => b.includes(lowerName) || lowerName.includes(b));
            if (matched)
                return matched;
        }
        const adminRoles = ['staff', 'admin', 'super_admin'];
        if (req.user?.role && adminRoles.includes(req.user.role)) {
            return null;
        }
        return null;
    }
};
exports.BankDashboardController = BankDashboardController;
__decorate([
    (0, common_1.Get)('products'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getProducts", null);
__decorate([
    (0, common_1.Post)('products'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "addProduct", null);
__decorate([
    (0, common_1.Put)('products/:productId'),
    __param(0, (0, common_1.Param)('productId')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "updateProduct", null);
__decorate([
    (0, common_1.Get)('branches'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getBranches", null);
__decorate([
    (0, common_1.Post)('branches'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "addBranch", null);
__decorate([
    (0, common_1.Post)('files'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "createFile", null);
__decorate([
    (0, common_1.Get)('files'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('status')),
    __param(2, (0, common_1.Query)('lanNumber')),
    __param(3, (0, common_1.Query)('bankId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "listFiles", null);
__decorate([
    (0, common_1.Get)('files/:fileId'),
    __param(0, (0, common_1.Param)('fileId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getFile", null);
__decorate([
    (0, common_1.Post)('files/:applicationId/log'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "logFile", null);
__decorate([
    (0, common_1.Get)('files/:fileId/log'),
    __param(0, (0, common_1.Param)('fileId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getFileLog", null);
__decorate([
    (0, common_1.Get)('files/by-lan/:lanNumber'),
    __param(0, (0, common_1.Param)('lanNumber')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getByLAN", null);
__decorate([
    (0, common_1.Post)('files/:fileId/documents'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('fileId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "uploadDocuments", null);
__decorate([
    (0, common_1.Get)('files/:fileId/documents'),
    __param(0, (0, common_1.Param)('fileId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getDocuments", null);
__decorate([
    (0, common_1.Get)('files/:fileId/documents/:documentId'),
    __param(0, (0, common_1.Param)('fileId')),
    __param(1, (0, common_1.Param)('documentId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getDocument", null);
__decorate([
    (0, common_1.Get)('files/:fileId/download'),
    __param(0, (0, common_1.Param)('fileId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "downloadDocuments", null);
__decorate([
    (0, common_1.Get)('files/:applicationId/timeline'),
    __param(0, (0, common_1.Param)('applicationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getFileTimeline", null);
__decorate([
    (0, common_1.Get)('files/:applicationId/events'),
    __param(0, (0, common_1.Param)('applicationId')),
    __param(1, (0, common_1.Query)('type')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getFileEvents", null);
__decorate([
    (0, common_1.Post)('lan/validate'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "validateLAN", null);
__decorate([
    (0, common_1.Get)('lan/:lanNumber'),
    __param(0, (0, common_1.Param)('lanNumber')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "checkLAN", null);
__decorate([
    (0, common_1.Get)('lan/:lanNumber/details'),
    __param(0, (0, common_1.Param)('lanNumber')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getLANDetails", null);
__decorate([
    (0, common_1.Put)('applications/:applicationId/roi'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "setROI", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/processing-fee'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "setProcessingFee", null);
__decorate([
    (0, common_1.Put)('applications/:applicationId/processing-fee'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "updateProcessingFee", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/sanction'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "sanctionApplication", null);
__decorate([
    (0, common_1.Put)('applications/:applicationId/sanction'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "updateSanction", null);
__decorate([
    (0, common_1.Post)('files/:id/decision'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "recordDecision", null);
__decorate([
    (0, common_1.Get)('applications/:applicationId/allowed-transitions'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getAllowedTransitions", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/transition'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "transitionStatus", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/decision'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "recordBankDecision", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/query'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "raiseQuery", null);
__decorate([
    (0, common_1.Get)('queries'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('applicationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getQueries", null);
__decorate([
    (0, common_1.Get)('queries/:queryId'),
    __param(0, (0, common_1.Param)('queryId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getQuery", null);
__decorate([
    (0, common_1.Post)('queries/:queryId/response'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queryId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "respondToQuery", null);
__decorate([
    (0, common_1.Get)('queries/:queryId/responses'),
    __param(0, (0, common_1.Param)('queryId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getQueryResponses", null);
__decorate([
    (0, common_1.Put)('queries/:queryId/resolve'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queryId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "resolveQuery", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/consent'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "recordConsent", null);
__decorate([
    (0, common_1.Get)('applications/:applicationId/consent'),
    __param(0, (0, common_1.Param)('applicationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getConsent", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/referral-fee'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "updateReferralFee", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/disbursement'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "confirmDisbursement", null);
__decorate([
    (0, common_1.Get)('applications/:applicationId/disbursements'),
    __param(0, (0, common_1.Param)('applicationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getDisbursements", null);
__decorate([
    (0, common_1.Get)('disbursements'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getAllDisbursements", null);
__decorate([
    (0, common_1.Post)('applications/:applicationId/quality-rating'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('applicationId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "rateQuality", null);
__decorate([
    (0, common_1.Get)('analytics/channel'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getChannelAnalytics", null);
__decorate([
    (0, common_1.Get)('analytics/rejections'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getRejectionAnalytics", null);
__decorate([
    (0, common_1.Get)('analytics/pipeline'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getPipelineAnalytics", null);
__decorate([
    (0, common_1.Get)('analytics/aging'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getAgingAnalytics", null);
__decorate([
    (0, common_1.Get)('analytics/sla'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getSLAAnalytics", null);
__decorate([
    (0, common_1.Get)('applications/:applicationId/audit-logs'),
    __param(0, (0, common_1.Param)('applicationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getAuditLogs", null);
__decorate([
    (0, common_1.Post)('files/:id/notes'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "addNote", null);
__decorate([
    (0, common_1.Get)('files/:id/notes'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getNotes", null);
__decorate([
    (0, common_1.Put)('files/:id/notes/:noteId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('noteId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "updateNote", null);
__decorate([
    (0, common_1.Delete)('files/:id/notes/:noteId'),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('noteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "deleteNote", null);
__decorate([
    (0, common_1.Get)('tags'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BankDashboardController.prototype, "getTagLibrary", null);
__decorate([
    (0, common_1.Post)('files/:id/tags'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "addTag", null);
__decorate([
    (0, common_1.Delete)('files/:id/tags/:tag'),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Param)('tag')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "removeTag", null);
__decorate([
    (0, common_1.Get)('files/by-tag/:tag'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('tag')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BankDashboardController.prototype, "getFilesByTag", null);
exports.BankDashboardController = BankDashboardController = __decorate([
    (0, common_1.Controller)('bank/dashboard'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    (0, common_1.UseInterceptors)(bank_rbac_middleware_1.BankRbacInterceptor),
    __metadata("design:paramtypes", [bank_dashboard_service_1.BankDashboardService,
        supabase_service_1.SupabaseService])
], BankDashboardController);
//# sourceMappingURL=bank-dashboard.controller.js.map