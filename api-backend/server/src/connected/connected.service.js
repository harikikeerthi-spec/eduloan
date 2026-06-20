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
exports.ConnectedService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let ConnectedService = class ConnectedService {
    supabase;
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase) {
        this.supabase = supabase;
    }
    async create(dto) {
        const { data: existing } = await this.db
            .from('CohortApplication')
            .select('id')
            .eq('email', dto.email)
            .eq('targetIntake', dto.targetIntake)
            .single();
        if (existing) {
            throw new common_1.ConflictException('An application with this email already exists for the selected intake.');
        }
        const { data: application, error } = await this.db
            .from('CohortApplication')
            .insert({
            fullName: dto.fullName,
            email: dto.email,
            phone: dto.phone,
            targetIntake: dto.targetIntake,
            destination: dto.destination,
            university: dto.university,
            course: dto.course,
            gapYear: dto.gapYear ?? false,
            message: dto.message,
            source: dto.source ?? 'connectED',
        })
            .select()
            .single();
        if (error)
            throw error;
        return { success: true, id: application.id };
    }
    async findAll(status) {
        let query = this.db
            .from('CohortApplication')
            .select('*')
            .order('createdAt', { ascending: false });
        if (status)
            query = query.eq('status', status);
        const { data } = await query;
        return data || [];
    }
    async updateStatus(id, status, reviewedBy, reviewNotes) {
        const { data, error } = await this.db
            .from('CohortApplication')
            .update({ status, reviewedBy, reviewNotes, reviewedAt: new Date().toISOString() })
            .eq('id', id)
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
};
exports.ConnectedService = ConnectedService;
exports.ConnectedService = ConnectedService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], ConnectedService);
//# sourceMappingURL=connected.service.js.map