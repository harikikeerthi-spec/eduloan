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
exports.StaffProfileController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const multer_1 = require("multer");
const staff_profile_service_1 = require("./staff-profile.service");
const staff_guard_1 = require("../auth/staff.guard");
const uploadStorage = (0, multer_1.memoryStorage)();
let StaffProfileController = class StaffProfileController {
    svc;
    constructor(svc) {
        this.svc = svc;
    }
    async list(req, search, bankStatus) {
        const profiles = await this.svc.listProfiles(req.user, { search, bankStatus });
        return { success: true, data: profiles, total: profiles.length };
    }
    async create(req, body) {
        if (!body.linked_user_id)
            throw new common_1.BadRequestException('linked_user_id is required');
        const profile = await this.svc.createProfile(req.user, body);
        return { success: true, data: profile };
    }
    async checkExists(userId) {
        const exists = await this.svc.getProfileByLinkedUserId(userId);
        return { success: true, exists: !!exists, data: exists || null };
    }
    async getOne(id) {
        const profile = await this.svc.getProfile(id);
        return { success: true, data: profile };
    }
    async fetchDocs(id, req) {
        const result = await this.svc.fetchUserDocuments(id, req.user);
        return { success: true, ...result };
    }
    async getDocs(id) {
        const docs = await this.svc.getProfileDocuments(id);
        return { success: true, data: docs };
    }
    async uploadDoc(id, req, file, docType, description) {
        if (!docType)
            throw new common_1.BadRequestException('doc_type is required');
        const doc = await this.svc.uploadStaffDocument(id, req.user, file, {
            doc_type: docType,
            description,
        });
        return { success: true, data: doc };
    }
    async updateStatus(id, docId, req, body) {
        const result = await this.svc.updateDocumentStatus(id, docId, req.user, body);
        return { success: true, data: result };
    }
    async removeDoc(id, docId, req) {
        return this.svc.removeDocument(id, docId, req.user);
    }
    async share(id, req, body) {
        const result = await this.svc.shareWithBank(id, req.user, body);
        return { success: true, data: result };
    }
    async shareProfile(studentId, req, body) {
        const result = await this.svc.shareProfile(studentId, req.user, body);
        return { success: true, ...result };
    }
    async getShares(id) {
        const shares = await this.svc.getShareHistory(id);
        return { success: true, data: shares };
    }
    async logActivity(req, body) {
        await this.svc.logDashboardActivity(req.user, body);
        return { success: true };
    }
    async getActivities(limit) {
        const logs = await this.svc.getDashboardActivities(limit ? parseInt(limit, 10) : 15);
        return { success: true, data: logs };
    }
    async getAllActivities(limit, offset, type, search) {
        const result = await this.svc.getAllDashboardActivities({
            limit: limit ? parseInt(limit, 10) : 50,
            offset: offset ? parseInt(offset, 10) : 0,
            type,
            search,
        });
        return { success: true, data: result.items, total: result.total };
    }
    async getTodayDashboard(req) {
        const data = await this.svc.getTodayDashboard(req.user);
        return { success: true, data };
    }
    async getDashboardSummary() {
        const data = await this.svc.getDashboardSummary();
        return { success: true, data };
    }
    async getRejectionAnalytics(period) {
        const data = await this.svc.getRejectionAnalytics(period || 'all');
        return { success: true, data };
    }
    async getSlaTracker() {
        const data = await this.svc.getSlaTracker();
        return { success: true, data };
    }
    async globalSearch(q) {
        const data = await this.svc.globalSearch(q || '');
        return { success: true, data };
    }
    async getAiPredictionScore(id) {
        const data = await this.svc.getAiPredictionScore(id);
        return { success: true, data };
    }
    async getDeadlineCalendar() {
        const data = await this.svc.getDeadlineCalendar();
        return { success: true, data };
    }
};
exports.StaffProfileController = StaffProfileController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('search')),
    __param(2, (0, common_1.Query)('bankStatus')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "list", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "create", null);
__decorate([
    (0, common_1.Get)('check/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "checkExists", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getOne", null);
__decorate([
    (0, common_1.Post)(':id/fetch-documents'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "fetchDocs", null);
__decorate([
    (0, common_1.Get)(':id/documents'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getDocs", null);
__decorate([
    (0, common_1.Post)(':id/documents'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('file', {
        storage: uploadStorage,
        limits: { fileSize: 20 * 1024 * 1024 },
        fileFilter: (_req, file, cb) => {
            const ext = file.originalname.split('.').pop()?.toLowerCase();
            const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
            const isMimeValid = file.mimetype.match(/\/(jpg|jpeg|png|pdf)$/) || file.mimetype === 'application/octet-stream';
            const isExtValid = ext && allowedExtensions.includes(ext);
            if (isMimeValid || isExtValid)
                cb(null, true);
            else
                cb(new common_1.BadRequestException('Only PDF, JPG, PNG allowed'), false);
        },
    })),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __param(2, (0, common_1.UploadedFile)()),
    __param(3, (0, common_1.Body)('doc_type')),
    __param(4, (0, common_1.Body)('description')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object, String, String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "uploadDoc", null);
__decorate([
    (0, common_1.Patch)(':id/documents/:docId/status'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('docId')),
    __param(2, (0, common_1.Req)()),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "updateStatus", null);
__decorate([
    (0, common_1.Delete)(':id/documents/:docId'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('docId')),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "removeDoc", null);
__decorate([
    (0, common_1.Post)(':id/share'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "share", null);
__decorate([
    (0, common_1.Post)('share-profile/:studentId'),
    __param(0, (0, common_1.Param)('studentId')),
    __param(1, (0, common_1.Req)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "shareProfile", null);
__decorate([
    (0, common_1.Get)(':id/shares'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getShares", null);
__decorate([
    (0, common_1.Post)('activities'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "logActivity", null);
__decorate([
    (0, common_1.Get)('dashboard/activities'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getActivities", null);
__decorate([
    (0, common_1.Get)('activities/all'),
    __param(0, (0, common_1.Query)('limit')),
    __param(1, (0, common_1.Query)('offset')),
    __param(2, (0, common_1.Query)('type')),
    __param(3, (0, common_1.Query)('search')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getAllActivities", null);
__decorate([
    (0, common_1.Get)('dashboard/today'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getTodayDashboard", null);
__decorate([
    (0, common_1.Get)('dashboard/summary'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getDashboardSummary", null);
__decorate([
    (0, common_1.Get)('dashboard/rejections'),
    __param(0, (0, common_1.Query)('period')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getRejectionAnalytics", null);
__decorate([
    (0, common_1.Get)('dashboard/sla'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getSlaTracker", null);
__decorate([
    (0, common_1.Get)('dashboard/search'),
    __param(0, (0, common_1.Query)('q')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "globalSearch", null);
__decorate([
    (0, common_1.Get)('dashboard/predict/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getAiPredictionScore", null);
__decorate([
    (0, common_1.Get)('dashboard/calendar'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], StaffProfileController.prototype, "getDeadlineCalendar", null);
exports.StaffProfileController = StaffProfileController = __decorate([
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    (0, common_1.Controller)('staff-profiles'),
    __metadata("design:paramtypes", [staff_profile_service_1.StaffProfileService])
], StaffProfileController);
//# sourceMappingURL=staff-profile.controller.js.map