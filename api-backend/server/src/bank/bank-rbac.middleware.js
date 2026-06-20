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
Object.defineProperty(exports, "__esModule", { value: true });
exports.BankRbacInterceptor = void 0;
const common_1 = require("@nestjs/common");
const operators_1 = require("rxjs/operators");
const supabase_service_1 = require("../supabase/supabase.service");
const BANK_ROLE_PERMISSIONS = {
    BANK_ADMIN: {
        canRead: ['all'],
        canWrite: ['all'],
        canDelete: ['all'],
        canApprove: ['all'],
        hiddenFields: []
    },
    BANK_OFFICER: {
        canRead: [
            'applications', 'files', 'documents', 'queries',
            'decisions', 'disbursements', 'auditLogs'
        ],
        canWrite: [
            'queries', 'files', 'documents', 'decisions',
            'disbursements', 'roi', 'processingFee'
        ],
        canDelete: ['queries', 'files'],
        canApprove: ['disbursements', 'decisions'],
        hiddenFields: [
            'agentCommission', 'referralFee', 'staffMetrics',
            'creditScore', 'internalNotes'
        ]
    },
    BANK_VIEWER: {
        canRead: [
            'applications', 'files', 'documents',
            'decisions', 'disbursements', 'auditLogs'
        ],
        canWrite: [],
        canDelete: [],
        canApprove: [],
        hiddenFields: [
            'agentCommission', 'referralFee', 'staffMetrics',
            'creditScore', 'internalNotes', 'processingFee',
            'sanctionAmount', 'roiBase'
        ]
    }
};
let BankRbacInterceptor = class BankRbacInterceptor {
    supabase;
    constructor(supabase) {
        this.supabase = supabase;
    }
    get db() {
        return this.supabase.getClient();
    }
    async intercept(context, next) {
        const request = context.switchToHttp().getRequest();
        const user = request.user;
        if (!user) {
            throw new common_1.ForbiddenException('Authentication required for bank operations.');
        }
        let role = user.role?.toUpperCase();
        if (role === 'BANK') {
            role = 'BANK_OFFICER';
        }
        const email = user.email;
        const method = request.method.toUpperCase();
        await this.validatePermission(role, method, request);
        const path = request.url;
        const appId = request.params.id || request.params.applicationId || request.query.applicationId || null;
        if (appId && (role === 'BANK' || role?.startsWith('BANK_'))) {
            await this.logDataAccess(email, appId, `${method} ${path}`, role);
        }
        return next.handle().pipe((0, operators_1.map)(async (data) => {
            const resolvedData = data instanceof Promise ? await data : data;
            return this.processPayload(resolvedData, role, email);
        }));
    }
    async validatePermission(role, method, request) {
        const permissions = BANK_ROLE_PERMISSIONS[role];
        if (!permissions) {
            throw new common_1.ForbiddenException(`Unknown role: ${role}`);
        }
        if (method === 'GET' && permissions.canRead.length === 0) {
            throw new common_1.ForbiddenException(`${role} does not have read permissions`);
        }
        if (['POST', 'PUT', 'PATCH'].includes(method) && permissions.canWrite.length === 0) {
            throw new common_1.ForbiddenException(`${role} does not have write permissions`);
        }
        if (method === 'DELETE' && permissions.canDelete.length === 0) {
            throw new common_1.ForbiddenException(`${role} does not have delete permissions`);
        }
    }
    async logDataAccess(userEmail, applicationId, action, role) {
        try {
            await this.db.from('AuditLog').insert({
                performedBy: userEmail,
                entityId: applicationId,
                entityType: 'ACCESS',
                action: action,
                role: role,
                createdAt: new Date().toISOString()
            });
            console.log(`[Audit] ${role} ${userEmail} performed: ${action} on App: ${applicationId}`);
        }
        catch (err) {
            console.error('[Audit] Failed to log access:', err.message);
        }
    }
    async checkConsent(userId) {
        try {
            const { data } = await this.db
                .from('ConsentRecord')
                .select('status')
                .eq('userId', userId)
                .eq('status', 'ACCEPTED')
                .limit(1)
                .maybeSingle();
            return !!data;
        }
        catch (err) {
            console.error('[Consent Check] Error:', err.message);
            return false;
        }
    }
    maskPII(value, maskLength = 4) {
        if (!value)
            return '';
        if (value.length <= maskLength)
            return '*'.repeat(value.length);
        const visiblePart = value.substring(value.length - maskLength);
        return '*'.repeat(value.length - maskLength) + visiblePart;
    }
    async processPayload(payload, role, userEmail) {
        if (!payload)
            return payload;
        const permissions = BANK_ROLE_PERMISSIONS[role];
        if (!permissions)
            return payload;
        if (Array.isArray(payload)) {
            return Promise.all(payload.map(item => this.processPayload(item, role, userEmail)));
        }
        if (typeof payload === 'object') {
            const cleaned = {};
            const hiddenFields = permissions.hiddenFields;
            for (const [key, value] of Object.entries(payload)) {
                if (hiddenFields.includes(key)) {
                    continue;
                }
                if (value && (Array.isArray(value) || typeof value === 'object')) {
                    cleaned[key] = await this.processPayload(value, role, userEmail);
                    continue;
                }
                cleaned[key] = value;
            }
            const studentUserId = payload.userId || payload.studentId;
            if (studentUserId && role === 'BANK_VIEWER') {
                const hasConsent = await this.checkConsent(studentUserId);
                if (!hasConsent) {
                    if (cleaned.aadhaar)
                        cleaned.aadhaar = this.maskPII(cleaned.aadhaar, 4);
                    if (cleaned.pan)
                        cleaned.pan = this.maskPII(cleaned.pan, 3);
                    if (cleaned.email && cleaned.email !== userEmail)
                        cleaned.email = 'masked@bank.com';
                    if (cleaned.phone)
                        cleaned.phone = this.maskPII(cleaned.phone, 3);
                }
            }
            return cleaned;
        }
        return payload;
    }
};
exports.BankRbacInterceptor = BankRbacInterceptor;
exports.BankRbacInterceptor = BankRbacInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], BankRbacInterceptor);
//# sourceMappingURL=bank-rbac.middleware.js.map