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
exports.AuditLogService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let AuditLogService = class AuditLogService {
    supabase;
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase) {
        this.supabase = supabase;
    }
    async logAction(action, entityType, entityId, user, changes, request) {
        try {
            await this.db.from('AuditLog').insert({
                action,
                entityType,
                entityId,
                initiatedBy: user.id,
                changes: changes || {},
                ipAddress: request?.ip || null,
                userAgent: request?.get?.('user-agent') || null,
            });
        }
        catch (error) {
            console.error('Failed to create audit log:', error);
        }
    }
    async getEntityLogs(entityType, entityId, limit = 50) {
        const { data } = await this.db
            .from('AuditLog')
            .select('id, action, initiatedBy, changes, createdAt, initiator:User!initiatedBy(firstName, lastName, email)')
            .eq('entityType', entityType)
            .eq('entityId', entityId)
            .order('createdAt', { ascending: false })
            .limit(limit);
        return data || [];
    }
    async getAllLogs(entityType, initiatedBy, limit = 100, offset = 0) {
        let query = this.db
            .from('AuditLog')
            .select('id, action, entityType, entityId, createdAt, initiator:User!initiatedBy(firstName, lastName, email)')
            .order('createdAt', { ascending: false })
            .range(offset, offset + limit - 1);
        if (entityType)
            query = query.eq('entityType', entityType);
        if (initiatedBy)
            query = query.eq('initiatedBy', initiatedBy);
        const { data } = await query;
        return data || [];
    }
};
exports.AuditLogService = AuditLogService;
exports.AuditLogService = AuditLogService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], AuditLogService);
//# sourceMappingURL=audit-log.service.js.map