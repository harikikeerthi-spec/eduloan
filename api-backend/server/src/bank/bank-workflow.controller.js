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
exports.BankWorkflowController = void 0;
const common_1 = require("@nestjs/common");
const bank_workflow_service_1 = require("./bank-workflow.service");
const staff_guard_1 = require("../auth/staff.guard");
let BankWorkflowController = class BankWorkflowController {
    workflowService;
    constructor(workflowService) {
        this.workflowService = workflowService;
    }
    async submitApplicationToBank(body, res) {
        try {
            const result = await this.workflowService.submitApplicationToBank(body.applicationId, body.bankId, body.bankName, body.submittedBy);
            return res.status(201).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async logFile(submissionId, body, res) {
        try {
            const result = await this.workflowService.logFile(submissionId, body.lanNumber, body.loggedBy, body.notes);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async moveToUnderReview(submissionId, body, res) {
        try {
            const result = await this.workflowService.moveToUnderReview(submissionId, body.changedBy, body.notes);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async raiseQuery(submissionId, body, res) {
        try {
            const result = await this.workflowService.raiseQuery(submissionId, body.queryType, body.queryDescription, body.raisedBy, body.dueDate ? new Date(body.dueDate) : undefined, body.docsChecklist || [], body.attachments || []);
            return res.status(201).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async respondToQuery(queryId, body, res) {
        try {
            const result = await this.workflowService.respondToQuery(queryId, body.response, body.respondedBy, body.attachments || [], body.docsChecklist || []);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async sanctionApplication(submissionId, body, res) {
        try {
            const result = await this.workflowService.sanctionApplication(submissionId, {
                sanctionAmount: body.sanctionAmount,
                roiType: body.roiType,
                roiBase: body.roiBase,
                roiEffective: body.roiEffective,
                roiSubsidy: body.roiSubsidy,
                tenure: body.tenure,
                decisionNotes: body.decisionNotes,
            }, body.decidedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async conditionalSanctionApplication(submissionId, body, res) {
        try {
            const result = await this.workflowService.conditionalSanctionApplication(submissionId, {
                sanctionAmount: body.sanctionAmount,
                roiType: body.roiType,
                roiBase: body.roiBase,
                roiEffective: body.roiEffective,
                tenure: body.tenure,
                conditions: body.conditions,
                decisionNotes: body.decisionNotes,
            }, body.decidedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async makeCounterOffer(submissionId, body, res) {
        try {
            const result = await this.workflowService.makeCounterOffer(submissionId, {
                sanctionAmount: body.sanctionAmount,
                roiType: body.roiType,
                roiBase: body.roiBase,
                roiEffective: body.roiEffective,
                tenure: body.tenure,
                terms: body.terms,
            }, body.decidedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async updateConditionStatus(submissionId, index, body, res) {
        try {
            const result = await this.workflowService.updateConditionStatus(submissionId, parseInt(index, 10), body.status, body.updatedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({ success: false, message: error.message });
        }
    }
    async acceptCounterOffer(submissionId, body, res) {
        try {
            const result = await this.workflowService.acceptCounterOffer(submissionId, body.acceptedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({ success: false, message: error.message });
        }
    }
    async rejectCounterOffer(submissionId, body, res) {
        try {
            const result = await this.workflowService.rejectCounterOffer(submissionId, body.reason, body.rejectedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({ success: false, message: error.message });
        }
    }
    async partialSanctionApplication(submissionId, body, res) {
        try {
            const result = await this.workflowService.partialSanctionApplication(submissionId, {
                approvedAmount: body.approvedAmount,
                requestedAmount: body.requestedAmount,
                roiType: body.roiType,
                roiBase: body.roiBase,
                roiEffective: body.roiEffective,
                tenure: body.tenure,
                decisionNotes: body.decisionNotes,
            }, body.decidedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({ success: false, message: error.message });
        }
    }
    async rejectApplication(submissionId, body, res) {
        try {
            const result = await this.workflowService.rejectApplication(submissionId, {
                reason: body.reason,
                category: body.category,
                decisionNotes: body.decisionNotes,
            }, body.decidedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async moveToProcessingFee(submissionId, body, res) {
        try {
            const result = await this.workflowService.moveToProcessingFee(submissionId, body.feeAmount, body.changedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async markFeeAsPaid(submissionId, body, res) {
        try {
            const result = await this.workflowService.markFeeAsPaid(submissionId, body.changedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async confirmDisbursement(submissionId, body, res) {
        try {
            const result = await this.workflowService.confirmDisbursement(submissionId, {
                amount: body.amount,
                referenceNo: body.referenceNo,
            }, body.confirmedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async allowResubmission(submissionId, body, res) {
        try {
            const result = await this.workflowService.allowResubmission(submissionId, body.authorizedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async getSubmissionDetails(submissionId, res) {
        try {
            const result = await this.workflowService.getSubmissionWithDetails(submissionId);
            return res.status(200).json({ success: true, data: result });
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async getBankIncomingApplications(bankId, res, status, limit, offset) {
        try {
            const result = await this.workflowService.getBankIncomingApplications(bankId, {
                status,
                limit: limit ? parseInt(limit) : 20,
                offset: offset ? parseInt(offset) : 0,
            });
            return res.status(200).json({ success: true, data: result.data, pagination: result.pagination });
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async getBankWorkflowAnalytics(bankId, res) {
        try {
            const result = await this.workflowService.getBankWorkflowAnalytics(bankId);
            return res.status(200).json({ success: true, data: result });
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async addQueryMessage(queryId, body, res) {
        try {
            const result = await this.workflowService.addQueryMessage(queryId, body.message, body.sender, body.attachments || []);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async createQueryTemplate(body, res) {
        try {
            const result = await this.workflowService.createQueryTemplate(body);
            return res.status(201).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async getQueryTemplatesByBank(bankId, res) {
        try {
            const result = await this.workflowService.getQueryTemplatesByBank(bankId);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async updateQueryTemplate(templateId, body, res) {
        try {
            const result = await this.workflowService.updateQueryTemplate(templateId, body);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async deleteQueryTemplate(templateId, res) {
        try {
            const result = await this.workflowService.deleteQueryTemplate(templateId);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async setSubmissionHold(submissionId, body, res) {
        try {
            const result = await this.workflowService.setSubmissionHold(submissionId, body.reason, body.changedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async resumeSubmissionHold(submissionId, body, res) {
        try {
            const result = await this.workflowService.resumeSubmissionHold(submissionId, body.changedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async bulkTransferSubmissions(body, res) {
        try {
            const result = await this.workflowService.bulkTransferSubmissions(body.submissionIds, body.officerId, body.officerName, body.changedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async updateFeeStatus(submissionId, body, res) {
        try {
            const result = await this.workflowService.updateFeeStatus(submissionId, body.status, body.paymentRef, body.changedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async scheduleDisbursementTranche(submissionId, body, res) {
        try {
            const result = await this.workflowService.scheduleDisbursementTranche(submissionId, body.amount, new Date(body.dueDate), body.remarks);
            return res.status(201).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async confirmDisbursementTranche(submissionId, trancheNumber, body, res) {
        try {
            const result = await this.workflowService.confirmDisbursementTranche(submissionId, parseInt(trancheNumber, 10), body.referenceNo, body.confirmedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async getTranchesSummary(submissionId, res) {
        try {
            const result = await this.workflowService.getTranchesSummary(submissionId);
            return res.status(200).json({ success: true, data: result });
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async amendSanctionTerms(submissionId, body, res) {
        try {
            const result = await this.workflowService.amendSanctionTerms(submissionId, body.newTerms, body.reason, new Date(body.effectiveDate), body.amendedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async requestCancellation(submissionId, body, res) {
        try {
            const result = await this.workflowService.requestCancellation(submissionId, body.reason, body.requestedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async confirmCancellation(submissionId, body, res) {
        try {
            const result = await this.workflowService.confirmCancellation(submissionId, body.confirmedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async submitQualityRating(submissionId, body, res) {
        try {
            const result = await this.workflowService.submitQualityRating(submissionId, body.ratings, body.comments, body.ratedBy);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async getCrossBankHistory(submissionId, res) {
        try {
            const result = await this.workflowService.getCrossBankHistory(submissionId);
            return res.status(200).json({ success: true, data: result });
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async grantStudentConsent(body, res) {
        try {
            const result = await this.workflowService.grantStudentConsent(body.studentId, body.bankId, body.isGranted, body.ipAddress, body.userAgent);
            return res.status(201).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async verifyStudentConsent(studentId, bankId, res) {
        try {
            const isGranted = await this.workflowService.verifyStudentConsent(studentId, bankId);
            return res.status(200).json({ success: true, isGranted });
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
    async getPipelineFunnelAnalytics(bankId, res) {
        try {
            const result = await this.workflowService.getPipelineFunnelAnalytics(bankId);
            return res.status(200).json(result);
        }
        catch (error) {
            return res.status(error.status || 400).json({
                success: false,
                message: error.message,
            });
        }
    }
};
exports.BankWorkflowController = BankWorkflowController;
__decorate([
    (0, common_1.Post)('submit'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "submitApplicationToBank", null);
__decorate([
    (0, common_1.Post)(':submissionId/log-file'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "logFile", null);
__decorate([
    (0, common_1.Put)(':submissionId/under-review'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "moveToUnderReview", null);
__decorate([
    (0, common_1.Post)(':submissionId/query'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "raiseQuery", null);
__decorate([
    (0, common_1.Post)('query/:queryId/respond'),
    __param(0, (0, common_1.Param)('queryId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "respondToQuery", null);
__decorate([
    (0, common_1.Post)(':submissionId/sanction'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "sanctionApplication", null);
__decorate([
    (0, common_1.Post)(':submissionId/conditional-sanction'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "conditionalSanctionApplication", null);
__decorate([
    (0, common_1.Post)(':submissionId/counter-offer'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "makeCounterOffer", null);
__decorate([
    (0, common_1.Put)(':submissionId/conditions/:index'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Param)('index')),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "updateConditionStatus", null);
__decorate([
    (0, common_1.Post)(':submissionId/counter-offer/accept'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "acceptCounterOffer", null);
__decorate([
    (0, common_1.Post)(':submissionId/counter-offer/reject'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "rejectCounterOffer", null);
__decorate([
    (0, common_1.Post)(':submissionId/partial-sanction'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "partialSanctionApplication", null);
__decorate([
    (0, common_1.Post)(':submissionId/reject'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "rejectApplication", null);
__decorate([
    (0, common_1.Put)(':submissionId/processing-fee'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "moveToProcessingFee", null);
__decorate([
    (0, common_1.Put)(':submissionId/fee-paid'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "markFeeAsPaid", null);
__decorate([
    (0, common_1.Post)(':submissionId/disburse'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "confirmDisbursement", null);
__decorate([
    (0, common_1.Put)(':submissionId/allow-resubmission'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "allowResubmission", null);
__decorate([
    (0, common_1.Get)(':submissionId'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "getSubmissionDetails", null);
__decorate([
    (0, common_1.Get)('bank/:bankId/incoming'),
    __param(0, (0, common_1.Param)('bankId')),
    __param(1, (0, common_1.Res)()),
    __param(2, (0, common_1.Query)('status')),
    __param(3, (0, common_1.Query)('limit')),
    __param(4, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, String, String, String]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "getBankIncomingApplications", null);
__decorate([
    (0, common_1.Get)('bank/:bankId/analytics'),
    __param(0, (0, common_1.Param)('bankId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "getBankWorkflowAnalytics", null);
__decorate([
    (0, common_1.Post)('query/:queryId/message'),
    __param(0, (0, common_1.Param)('queryId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "addQueryMessage", null);
__decorate([
    (0, common_1.Post)('templates'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "createQueryTemplate", null);
__decorate([
    (0, common_1.Get)('templates/bank/:bankId'),
    __param(0, (0, common_1.Param)('bankId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "getQueryTemplatesByBank", null);
__decorate([
    (0, common_1.Put)('templates/:templateId'),
    __param(0, (0, common_1.Param)('templateId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "updateQueryTemplate", null);
__decorate([
    (0, common_1.Post)('templates/:templateId/delete'),
    __param(0, (0, common_1.Param)('templateId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "deleteQueryTemplate", null);
__decorate([
    (0, common_1.Post)(':submissionId/hold'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "setSubmissionHold", null);
__decorate([
    (0, common_1.Post)(':submissionId/resume'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "resumeSubmissionHold", null);
__decorate([
    (0, common_1.Post)('transfer'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "bulkTransferSubmissions", null);
__decorate([
    (0, common_1.Put)(':submissionId/fee-status'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "updateFeeStatus", null);
__decorate([
    (0, common_1.Post)(':submissionId/tranches'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "scheduleDisbursementTranche", null);
__decorate([
    (0, common_1.Post)(':submissionId/tranches/:trancheNumber/confirm'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Param)('trancheNumber')),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "confirmDisbursementTranche", null);
__decorate([
    (0, common_1.Get)(':submissionId/tranches'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "getTranchesSummary", null);
__decorate([
    (0, common_1.Post)(':submissionId/amend'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "amendSanctionTerms", null);
__decorate([
    (0, common_1.Post)(':submissionId/cancel-request'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "requestCancellation", null);
__decorate([
    (0, common_1.Post)(':submissionId/cancel-confirm'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "confirmCancellation", null);
__decorate([
    (0, common_1.Post)(':submissionId/rate'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "submitQualityRating", null);
__decorate([
    (0, common_1.Get)(':submissionId/cross-bank-history'),
    __param(0, (0, common_1.Param)('submissionId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "getCrossBankHistory", null);
__decorate([
    (0, common_1.Post)('consent'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "grantStudentConsent", null);
__decorate([
    (0, common_1.Get)('consent/verify'),
    __param(0, (0, common_1.Query)('studentId')),
    __param(1, (0, common_1.Query)('bankId')),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "verifyStudentConsent", null);
__decorate([
    (0, common_1.Get)('funnel/analytics'),
    __param(0, (0, common_1.Query)('bankId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BankWorkflowController.prototype, "getPipelineFunnelAnalytics", null);
exports.BankWorkflowController = BankWorkflowController = __decorate([
    (0, common_1.Controller)('api/bank/workflow'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __metadata("design:paramtypes", [bank_workflow_service_1.BankWorkflowService])
], BankWorkflowController);
//# sourceMappingURL=bank-workflow.controller.js.map