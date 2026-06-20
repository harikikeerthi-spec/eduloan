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
exports.ReferenceService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let ReferenceService = class ReferenceService {
    supabase;
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase) {
        this.supabase = supabase;
    }
    async getAllLoanTypes() {
        const { data } = await this.db
            .from('LoanType')
            .select('*')
            .order('isPopular', { ascending: false })
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getPopularLoanTypes() {
        const { data } = await this.db
            .from('LoanType')
            .select('*')
            .eq('isPopular', true)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getLoanTypeById(id) {
        const { data } = await this.db.from('LoanType').select('*').eq('id', id).single();
        return { success: true, data };
    }
    async getAllUniversities(filters) {
        const { country, ranking, limit = 20, offset = 0 } = filters;
        let query = this.db
            .from('University')
            .select('*', { count: 'exact' })
            .order('isFeatured', { ascending: false })
            .order('ranking', { ascending: true })
            .range(offset, offset + limit - 1);
        if (country)
            query = query.ilike('country', `%${country}%`);
        if (ranking)
            query = query.lte('ranking', parseInt(ranking));
        const { data, count } = await query;
        return {
            success: true,
            data: data || [],
            pagination: { total: count || 0, limit, offset, hasMore: offset + (data?.length || 0) < (count || 0) },
        };
    }
    async getFeaturedUniversities(limit) {
        const { data } = await this.db
            .from('University')
            .select('*')
            .eq('isFeatured', true)
            .order('ranking', { ascending: true })
            .limit(limit);
        return { success: true, data: data || [] };
    }
    async getUniversityById(id) {
        const { data } = await this.db.from('University').select('*').eq('id', id).single();
        return { success: true, data };
    }
    async getUniversitiesByCountry(country) {
        const { data } = await this.db
            .from('University')
            .select('*')
            .ilike('country', country)
            .order('ranking', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getAllBanks() {
        const { data } = await this.db
            .from('Bank')
            .select('*')
            .order('isPopular', { ascending: false })
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getPopularBanks() {
        const { data } = await this.db
            .from('Bank')
            .select('*')
            .eq('isPopular', true)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getBankById(id) {
        const { data } = await this.db.from('Bank').select('*').eq('id', id).single();
        return { success: true, data };
    }
    async getBanksByType(type) {
        const { data } = await this.db
            .from('Bank')
            .select('*')
            .eq('type', type)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getAllCountries() {
        const { data } = await this.db
            .from('Country')
            .select('*')
            .order('popularForStudy', { ascending: false })
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getPopularCountries() {
        const { data } = await this.db
            .from('Country')
            .select('*')
            .eq('popularForStudy', true)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getCountryById(id) {
        const { data } = await this.db.from('Country').select('*').eq('id', id).single();
        return { success: true, data };
    }
    async getCountryByCode(code) {
        const { data } = await this.db
            .from('Country')
            .select('*')
            .eq('code', code.toUpperCase())
            .single();
        return { success: true, data };
    }
    async getCountriesByRegion(region) {
        const { data } = await this.db
            .from('Country')
            .select('*')
            .ilike('region', `%${region}%`)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getAllScholarships(filters) {
        const { country, type, limit = 20, offset = 0 } = filters;
        let query = this.db
            .from('Scholarship')
            .select('*', { count: 'exact' })
            .eq('isActive', true)
            .order('createdAt', { ascending: false })
            .range(offset, offset + limit - 1);
        if (country)
            query = query.ilike('country', `%${country}%`);
        if (type)
            query = query.eq('type', type);
        const { data, count } = await query;
        return {
            success: true,
            data: data || [],
            pagination: { total: count || 0, limit, offset, hasMore: offset + (data?.length || 0) < (count || 0) },
        };
    }
    async getScholarshipById(id) {
        const { data } = await this.db.from('Scholarship').select('*').eq('id', id).single();
        return { success: true, data };
    }
    async getScholarshipsByCountry(country) {
        const { data } = await this.db
            .from('Scholarship')
            .select('*')
            .ilike('country', country)
            .eq('isActive', true)
            .order('createdAt', { ascending: false });
        return { success: true, data: data || [] };
    }
    async getAllCourses(filters) {
        const { level, field, limit = 20, offset = 0 } = filters;
        let query = this.db
            .from('Course')
            .select('*', { count: 'exact' })
            .order('isPopular', { ascending: false })
            .order('name', { ascending: true })
            .range(offset, offset + limit - 1);
        if (level)
            query = query.ilike('level', `%${level}%`);
        if (field)
            query = query.ilike('field', `%${field}%`);
        const { data, count } = await query;
        return {
            success: true,
            data: data || [],
            pagination: { total: count || 0, limit, offset, hasMore: offset + (data?.length || 0) < (count || 0) },
        };
    }
    async getPopularCourses() {
        const { data } = await this.db
            .from('Course')
            .select('*')
            .eq('isPopular', true)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getCourseById(id) {
        const { data } = await this.db.from('Course').select('*').eq('id', id).single();
        return { success: true, data };
    }
    async getCoursesByLevel(level) {
        const { data } = await this.db
            .from('Course')
            .select('*')
            .ilike('level', `%${level}%`)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
    async getCoursesByField(field) {
        const { data } = await this.db
            .from('Course')
            .select('*')
            .ilike('field', `%${field}%`)
            .order('name', { ascending: true });
        return { success: true, data: data || [] };
    }
};
exports.ReferenceService = ReferenceService;
exports.ReferenceService = ReferenceService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], ReferenceService);
//# sourceMappingURL=reference.service.js.map