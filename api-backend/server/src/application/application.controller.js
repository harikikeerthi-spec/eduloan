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
exports.ApplicationController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const multer_1 = require("multer");
const path_1 = require("path");
const fs_1 = require("fs");
const application_service_1 = require("./application.service");
const user_guard_1 = require("../auth/user.guard");
const staff_guard_1 = require("../auth/staff.guard");
const agent_guard_1 = require("../auth/agent.guard");
const storage = (0, multer_1.diskStorage)({
    destination: (req, file, cb) => {
        const uploadPath = './uploads/applications';
        if (!(0, fs_1.existsSync)(uploadPath)) {
            (0, fs_1.mkdirSync)(uploadPath, { recursive: true });
        }
        cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const ext = (0, path_1.extname)(file.originalname);
        cb(null, `app-doc-${uniqueSuffix}${ext}`);
    },
});
let ApplicationController = class ApplicationController {
    applicationService;
    constructor(applicationService) {
        this.applicationService = applicationService;
    }
    async trackApplication(applicationNumber) {
        return this.applicationService.trackApplication(applicationNumber);
    }
    async getRequiredDocuments(loanType) {
        return this.applicationService.getRequiredDocuments(loanType);
    }
    async getApplicationStages() {
        return this.applicationService.getApplicationStages();
    }
    async createApplication(req, body) {
        return this.applicationService.createApplication(req.user.id, body);
    }
    async getMyApplications(req, status, loanType, limit, offset) {
        return this.applicationService.getUserApplications(req.user.id, {
            status,
            loanType,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getAllApplications(status, stage, loanType, bank, search, fromDate, toDate, limit, offset, sortBy, sortOrder, userId, excludeStatus) {
        let dbBankName = bank;
        if (bank) {
            const mappings = {
                credila: 'HDFC Credila',
                poonawalla: 'Poonawalla Fincorp',
                idfc: 'IDFC First Bank',
                avanse: 'Avanse Financial Services',
                auxilo: 'Auxilo'
            };
            dbBankName = mappings[bank.toLowerCase()] || bank;
        }
        return this.applicationService.getAllApplications({
            status,
            stage,
            loanType,
            bank: dbBankName,
            search,
            fromDate,
            toDate,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
            sortBy,
            sortOrder: sortOrder,
            userId,
            excludeStatus,
        });
    }
    async getApplicationStats(req, bankId) {
        return this.applicationService.getApplicationStats(req.user, bankId);
    }
    async getDocumentsAdmin(id) {
        return this.applicationService.getApplicationDocuments(id);
    }
    async syncVaultDocuments(id) {
        return this.applicationService.syncApplicationDocuments(id);
    }
    async updateApplicationDetails(id, body) {
        return this.applicationService.adminUpdateApplication(id, body);
    }
    async updateApplicationStatus(req, id, body) {
        const adminName = `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim() || req.user.email;
        return this.applicationService.updateApplicationStatus(id, req.user.id, adminName, body, req.user.role);
    }
    async aiReviewApplication(req, id) {
        try {
            const adminName = `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim() || req.user.email;
            console.log(`[AI Review] Starting review for application ${id} by admin ${adminName}`);
            return await this.applicationService.aiReviewApplication(id, req.user.id, adminName);
        }
        catch (error) {
            console.error(`[AI Review] Controller Error for application ${id}:`, error);
            throw error;
        }
    }
    async shareApplication(req, id) {
        const adminName = `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim() || req.user.email;
        return this.applicationService.shareApplication(id, req.user.id, adminName);
    }
    async viewDocumentAdmin(applicationId, documentId, res) {
        const docsResult = await this.applicationService.getApplicationDocuments(applicationId);
        const doc = docsResult.data?.find((d) => String(d.id) === String(documentId));
        if (!doc || !doc.filePath) {
            throw new common_1.NotFoundException('Document not found');
        }
        if (doc.filePath && doc.filePath.startsWith('in.gov.')) {
            const html = `
<!DOCTYPE html>
<html>
<head>
    <title>DigiLocker Record - ${doc.docName || doc.docType}</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #f0f2f5; display: flex; justify-content: center; padding: 40px; }
        .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 600px; width: 100%; border-top: 6px solid #82c91e; }
        .header { display: flex; align-items: center; gap: 15px; margin-bottom: 30px; border-bottom: 1px solid #eee; padding-bottom: 20px; }
        .title { margin: 0; color: #1a3a6b; }
        .badge { background: #e6fced; color: #12b842; padding: 6px 12px; border-radius: 20px; font-weight: 600; font-size: 14px; white-space: nowrap; }
        .field { margin-bottom: 20px; }
        .label { font-size: 13px; color: #666; text-transform: uppercase; font-weight: 600; letter-spacing: 0.5px; }
        .value { font-size: 18px; color: #333; margin-top: 4px; word-break: break-all; }
        .footer { margin-top: 40px; font-size: 12px; color: #888; text-align: center; }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <h2 class="title">Digital Verification Record</h2>
            <span class="badge">✓ Verified by DigiLocker</span>
        </div>
        <div class="field">
            <div class="label">Document Name</div>
            <div class="value">${doc.docName || doc.docType || 'Document'}</div>
        </div>
        <div class="field">
            <div class="label">DigiLocker Reference URI</div>
            <div class="value">${doc.filePath}</div>
        </div>
        <div class="field">
            <div class="label">Date Synced</div>
            <div class="value">${doc.uploadedAt ? new Date(doc.uploadedAt).toLocaleString() : 'N/A'}</div>
        </div>
        <div class="footer">
            This is a digitally verified record synced directly from DigiLocker. The physical file is held securely by the issuing authority.
        </div>
    </div>
</body>
</html>`;
            res.setHeader('Content-Type', 'text/html');
            return res.send(html);
        }
        const absolutePath = (0, path_1.resolve)(doc.filePath);
        if (!(0, fs_1.existsSync)(absolutePath)) {
            const fallbackPath = (0, path_1.resolve)(process.cwd(), 'public/mock/document_missing.pdf');
            if ((0, fs_1.existsSync)(fallbackPath)) {
                return res.sendFile(fallbackPath);
            }
            throw new common_1.NotFoundException('Document file not found on disk');
        }
        res.sendFile(absolutePath);
    }
    async verifyDocument(req, documentId, body) {
        return this.applicationService.verifyDocument(documentId, req.user.id, body);
    }
    async getTrackingAdmin(id) {
        return this.applicationService.getApplicationTracking(id);
    }
    async getApplicationNotes(id) {
        return this.applicationService.getApplicationNotes(id, true);
    }
    async addApplicationNote(req, id, body) {
        const authorName = `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim() || req.user.email;
        return this.applicationService.addApplicationNote(id, req.user.id, authorName, body);
    }
    async getAgentStats(req) {
        return this.applicationService.getAgentStats(req.user.id);
    }
    async getAgentApplications(req) {
        return this.applicationService.getAgentApplications(req.user.id);
    }
    async getApplicationById(req, id) {
        const application = await this.applicationService.getApplicationById(id);
        if (req.user.role !== 'admin' && req.user.role !== 'super_admin' && application.userId !== req.user.id) {
            throw new common_1.BadRequestException('Unauthorized to view this application');
        }
        return {
            success: true,
            data: application
        };
    }
    async getApplicationTracking(req, id) {
        return this.applicationService.getApplicationTracking(id, req.user.id);
    }
    async updateApplication(req, id, body) {
        return this.applicationService.updateApplication(id, req.user.id, body);
    }
    async submitApplication(req, id) {
        return this.applicationService.submitApplication(id, req.user.id);
    }
    async cancelApplication(req, id, body) {
        return this.applicationService.cancelApplication(id, req.user.id, body?.reason);
    }
    async getApplicationDocuments(req, id) {
        return this.applicationService.getApplicationDocuments(id, req.user.id);
    }
    async uploadDocument(req, applicationId, file, docType, docName) {
        if (!file) {
            throw new common_1.BadRequestException('File is required');
        }
        if (!docType) {
            if (file?.path) {
                try {
                    (0, fs_1.unlinkSync)(file.path);
                }
                catch (e) { }
            }
            throw new common_1.BadRequestException('docType is required');
        }
        return this.applicationService.uploadDocument(applicationId, req.user.id, {
            docType,
            docName: docName || file.originalname,
            fileName: file.filename,
            filePath: file.path,
            fileSize: file.size,
            mimeType: file.mimetype,
        });
    }
    async deleteDocument(req, applicationId, documentId) {
        return this.applicationService.deleteDocument(documentId, req.user.id);
    }
};
exports.ApplicationController = ApplicationController;
__decorate([
    (0, common_1.Get)('track/:applicationNumber'),
    __param(0, (0, common_1.Param)('applicationNumber')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "trackApplication", null);
__decorate([
    (0, common_1.Get)('required-documents/:loanType'),
    __param(0, (0, common_1.Param)('loanType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getRequiredDocuments", null);
__decorate([
    (0, common_1.Get)('stages'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getApplicationStages", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "createApplication", null);
__decorate([
    (0, common_1.Get)('my'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('status')),
    __param(2, (0, common_1.Query)('loanType')),
    __param(3, (0, common_1.Query)('limit')),
    __param(4, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getMyApplications", null);
__decorate([
    (0, common_1.Get)('admin/all'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Query)('status')),
    __param(1, (0, common_1.Query)('stage')),
    __param(2, (0, common_1.Query)('loanType')),
    __param(3, (0, common_1.Query)('bank')),
    __param(4, (0, common_1.Query)('search')),
    __param(5, (0, common_1.Query)('fromDate')),
    __param(6, (0, common_1.Query)('toDate')),
    __param(7, (0, common_1.Query)('limit')),
    __param(8, (0, common_1.Query)('offset')),
    __param(9, (0, common_1.Query)('sortBy')),
    __param(10, (0, common_1.Query)('sortOrder')),
    __param(11, (0, common_1.Query)('userId')),
    __param(12, (0, common_1.Query)('excludeStatus')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String, String, String, String, String, String, String, String, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getAllApplications", null);
__decorate([
    (0, common_1.Get)('admin/stats'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('bankId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getApplicationStats", null);
__decorate([
    (0, common_1.Get)('admin/:id/documents'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getDocumentsAdmin", null);
__decorate([
    (0, common_1.Post)('admin/:id/sync-vault'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "syncVaultDocuments", null);
__decorate([
    (0, common_1.Put)('admin/:id'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "updateApplicationDetails", null);
__decorate([
    (0, common_1.Put)('admin/:id/status'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "updateApplicationStatus", null);
__decorate([
    (0, common_1.Post)('admin/:id/ai-review'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "aiReviewApplication", null);
__decorate([
    (0, common_1.Post)('admin/:id/share'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "shareApplication", null);
__decorate([
    (0, common_1.Get)('admin/:id/documents/:documentId/view'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('documentId')),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "viewDocumentAdmin", null);
__decorate([
    (0, common_1.Put)('admin/documents/:documentId/verify'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('documentId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "verifyDocument", null);
__decorate([
    (0, common_1.Get)('admin/:id/tracking'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getTrackingAdmin", null);
__decorate([
    (0, common_1.Get)('admin/:id/notes'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getApplicationNotes", null);
__decorate([
    (0, common_1.Post)('admin/:id/notes'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "addApplicationNote", null);
__decorate([
    (0, common_1.Get)('agent/stats'),
    (0, common_1.UseGuards)(agent_guard_1.AgentGuard),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getAgentStats", null);
__decorate([
    (0, common_1.Get)('agent/list'),
    (0, common_1.UseGuards)(agent_guard_1.AgentGuard),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getAgentApplications", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getApplicationById", null);
__decorate([
    (0, common_1.Get)(':id/tracking'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getApplicationTracking", null);
__decorate([
    (0, common_1.Put)(':id'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "updateApplication", null);
__decorate([
    (0, common_1.Post)(':id/submit'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "submitApplication", null);
__decorate([
    (0, common_1.Post)(':id/cancel'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "cancelApplication", null);
__decorate([
    (0, common_1.Get)(':id/documents'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "getApplicationDocuments", null);
__decorate([
    (0, common_1.Post)(':id/documents'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('file', {
        storage: storage,
        limits: { fileSize: 10 * 1024 * 1024 },
        fileFilter: (req, file, cb) => {
            const ext = file.originalname.split('.').pop()?.toLowerCase();
            const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
            const isMimeValid = file.mimetype.match(/\/(jpg|jpeg|png|pdf|doc|docx)$/) || file.mimetype === 'application/octet-stream';
            const isExtValid = ext && allowedExtensions.includes(ext);
            if (isMimeValid || isExtValid) {
                cb(null, true);
            }
            else {
                cb(new common_1.BadRequestException('Unsupported file type. Allowed: jpg, jpeg, png, pdf, doc, docx'), false);
            }
        }
    })),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.UploadedFile)()),
    __param(3, (0, common_1.Body)('docType')),
    __param(4, (0, common_1.Body)('docName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object, String, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "uploadDocument", null);
__decorate([
    (0, common_1.Delete)(':id/documents/:documentId'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Param)('documentId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], ApplicationController.prototype, "deleteDocument", null);
exports.ApplicationController = ApplicationController = __decorate([
    (0, common_1.Controller)('applications'),
    __metadata("design:paramtypes", [application_service_1.ApplicationService])
], ApplicationController);
//# sourceMappingURL=application.controller.js.map