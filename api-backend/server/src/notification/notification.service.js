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
var NotificationService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const event_emitter_1 = require("@nestjs/event-emitter");
let NotificationService = NotificationService_1 = class NotificationService {
    supabase;
    eventEmitter;
    logger = new common_1.Logger(NotificationService_1.name);
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase, eventEmitter) {
        this.supabase = supabase;
        this.eventEmitter = eventEmitter;
    }
    async createNotification(userId, title, body, type, metadata) {
        this.logger.log(`Creating notification of type ${type} for User ID ${userId}: ${title}`);
        const newNotif = {
            id: 'notif-' + Date.now() + '-' + Math.floor(Math.random() * 1000),
            userId,
            title,
            body,
            type,
            isRead: false,
            timestamp: new Date().toISOString(),
            metadata: metadata || null,
        };
        const { data, error } = await this.db
            .from('Notification')
            .insert(newNotif)
            .select()
            .single();
        if (error) {
            this.logger.error(`Failed to store notification in DB: ${error.message}`);
        }
        const payload = data || newNotif;
        this.eventEmitter.emit('notification.created', {
            ...payload,
            metadata,
        });
        return payload;
    }
    async getNotificationsForUser(user, type, limit = 30, offset = 0) {
        const isStaffOrAdmin = user.role === 'staff' || user.role === 'admin' || user.role === 'super_admin';
        const isBank = user.role === 'bank' || user.role === 'partner_bank';
        const userId = user.id || user.uid || user._id;
        let query = this.db.from('Notification').select('*', { count: 'exact' });
        if (isStaffOrAdmin) {
            query = query.or(`userId.eq.staff,userId.eq.system,userId.eq.all,userId.eq.${userId}`);
        }
        else if (isBank) {
            query = query.or(`userId.eq.bank,userId.eq.system,userId.eq.all,userId.eq.${userId}`);
        }
        else {
            query = query.or(`userId.eq.${userId},userId.eq.all`);
        }
        if (type && type !== 'all') {
            query = query.eq('type', type);
        }
        const { data, error, count } = await query
            .order('timestamp', { ascending: false })
            .range(offset, offset + limit - 1);
        if (error) {
            this.logger.error(`Failed to fetch notifications: ${error.message}`);
            return { items: [], total: 0 };
        }
        return {
            items: data || [],
            total: count || (data || []).length,
        };
    }
    async markAsRead(notificationId, user) {
        const { data, error } = await this.db
            .from('Notification')
            .update({ isRead: true })
            .eq('id', notificationId)
            .select()
            .single();
        if (error) {
            this.logger.error(`Failed to mark notification as read: ${error.message}`);
            throw error;
        }
        return data;
    }
    async markAllAsRead(user) {
        const isStaffOrAdmin = user.role === 'staff' || user.role === 'admin' || user.role === 'super_admin';
        const isBank = user.role === 'bank' || user.role === 'partner_bank';
        const userId = user.id || user.uid || user._id;
        let query = this.db.from('Notification').update({ isRead: true });
        if (isStaffOrAdmin) {
            query = query.or(`userId.eq.staff,userId.eq.system,userId.eq.all,userId.eq.${userId}`);
        }
        else if (isBank) {
            query = query.or(`userId.eq.bank,userId.eq.system,userId.eq.all,userId.eq.${userId}`);
        }
        else {
            query = query.or(`userId.eq.${userId},userId.eq.all`);
        }
        const { data, error } = await query.eq('isRead', false).select();
        if (error) {
            this.logger.error(`Failed to mark all notifications as read: ${error.message}`);
            throw error;
        }
        return { success: true, count: data?.length || 0 };
    }
    async handleCandidateRegistered(payload) {
        try {
            const candidateName = payload.firstName || 'New Candidate';
            await this.createNotification('staff', `🎉 New Candidate Registered: ${candidateName}`, `${candidateName} has registered on Vidyaloan. Email: ${payload.email}`, 'candidate_registered', {
                userId: payload.userId,
                email: payload.email,
                phoneNumber: payload.phoneNumber,
                dateOfBirth: payload.dateOfBirth,
                registeredAt: payload.createdAt
            });
        }
        catch (error) {
            this.logger.error(`Failed to handle candidate registration event: ${error.message}`);
        }
    }
    async handleApplicationCreated(payload) {
        try {
            const candidateName = payload.candidateName || 'Candidate';
            await this.createNotification('staff', `📋 New Application Created: ${candidateName}`, `${candidateName} created a new loan application (${payload.loanType}) for ${payload.bank || 'a bank'}. Application #${payload.applicationNumber}`, 'application_created', {
                applicationId: payload.applicationId,
                applicationNumber: payload.applicationNumber,
                userId: payload.userId,
                candidateName: payload.candidateName,
                candidateEmail: payload.candidateEmail,
                bank: payload.bank,
                loanAmount: payload.loanAmount,
                loanType: payload.loanType,
                createdAt: payload.createdAt
            });
        }
        catch (error) {
            this.logger.error(`Failed to handle application created event: ${error.message}`);
        }
    }
    async handleApplicationSubmitted(payload) {
        try {
            const candidateName = payload.candidateName || 'Candidate';
            await this.createNotification('staff', `🚀 Application Submitted: ${candidateName}`, `${candidateName} submitted a loan application for ${payload.bank || 'a bank'}. Application #${payload.applicationNumber}`, 'application_submitted', {
                applicationId: payload.applicationId,
                applicationNumber: payload.applicationNumber,
                userId: payload.userId,
                candidateName: payload.candidateName,
                candidateEmail: payload.candidateEmail,
                bank: payload.bank,
                loanAmount: payload.loanAmount,
                loanType: payload.loanType,
                submittedAt: payload.submittedAt
            });
        }
        catch (error) {
            this.logger.error(`Failed to handle application submitted event: ${error.message}`);
        }
    }
    async handleDocumentUploaded(payload) {
        try {
            const candidateName = payload.candidateName || 'Candidate';
            const docName = payload.documentName || payload.documentType;
            await this.createNotification('staff', `📄 Document Uploaded: ${docName}`, `${candidateName} has uploaded ${docName} for application #${payload.applicationNumber}. Status: ${payload.status}`, 'document_uploaded', {
                applicationId: payload.applicationId,
                applicationNumber: payload.applicationNumber,
                userId: payload.userId,
                candidateName: payload.candidateName,
                candidateEmail: payload.candidateEmail,
                documentType: payload.documentType,
                documentName: payload.documentName,
                status: payload.status,
                createdAt: payload.createdAt
            });
        }
        catch (error) {
            this.logger.error(`Failed to handle document uploaded event: ${error.message}`);
        }
    }
    async handleDocumentRejected(payload) {
        try {
            const docName = payload.documentName || payload.documentType;
            await this.createNotification(payload.userId, `❌ Document Rejected: ${docName}`, `Your uploaded ${docName} has been rejected. Reason: ${payload.rejectionReason}`, 'document_rejected', {
                documentId: payload.documentId,
                documentType: payload.documentType,
                documentName: payload.documentName,
                rejectionReason: payload.rejectionReason,
                rejectedAt: payload.rejectedAt,
            });
        }
        catch (error) {
            this.logger.error(`Failed to handle document rejected event: ${error.message}`);
        }
    }
    async handleDocumentVerified(payload) {
        try {
            const docName = payload.documentName || payload.documentType;
            await this.createNotification(payload.userId, `✅ Document Approved: ${docName}`, `Your uploaded ${docName} has been successfully verified.`, 'document_verified', {
                documentId: payload.documentId,
                documentType: payload.documentType,
                documentName: payload.documentName,
                verifiedAt: payload.verifiedAt,
            });
        }
        catch (error) {
            this.logger.error(`Failed to handle document verified event: ${error.message}`);
        }
    }
};
exports.NotificationService = NotificationService;
__decorate([
    (0, event_emitter_1.OnEvent)('candidate.registered'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], NotificationService.prototype, "handleCandidateRegistered", null);
__decorate([
    (0, event_emitter_1.OnEvent)('application.created'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], NotificationService.prototype, "handleApplicationCreated", null);
__decorate([
    (0, event_emitter_1.OnEvent)('application.submitted'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], NotificationService.prototype, "handleApplicationSubmitted", null);
__decorate([
    (0, event_emitter_1.OnEvent)('document.uploaded'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], NotificationService.prototype, "handleDocumentUploaded", null);
__decorate([
    (0, event_emitter_1.OnEvent)('document.rejected'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], NotificationService.prototype, "handleDocumentRejected", null);
__decorate([
    (0, event_emitter_1.OnEvent)('document.verified'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], NotificationService.prototype, "handleDocumentVerified", null);
exports.NotificationService = NotificationService = NotificationService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        event_emitter_1.EventEmitter2])
], NotificationService);
//# sourceMappingURL=notification.service.js.map