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
exports.ReferenceController = void 0;
const common_1 = require("@nestjs/common");
const reference_service_1 = require("./reference.service");
let ReferenceController = class ReferenceController {
    referenceService;
    constructor(referenceService) {
        this.referenceService = referenceService;
    }
    async getAllLoanTypes() {
        return this.referenceService.getAllLoanTypes();
    }
    async getPopularLoanTypes() {
        return this.referenceService.getPopularLoanTypes();
    }
    async getLoanTypeById(id) {
        return this.referenceService.getLoanTypeById(id);
    }
    async getAllUniversities(country, ranking, limit, offset) {
        return this.referenceService.getAllUniversities({
            country,
            ranking,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getFeaturedUniversities(limit) {
        return this.referenceService.getFeaturedUniversities(limit ? parseInt(limit, 10) : 10);
    }
    async getUniversityById(id) {
        return this.referenceService.getUniversityById(id);
    }
    async getUniversitiesByCountry(country) {
        return this.referenceService.getUniversitiesByCountry(country);
    }
    async getAllBanks() {
        return this.referenceService.getAllBanks();
    }
    async getPopularBanks() {
        return this.referenceService.getPopularBanks();
    }
    async getBankById(id) {
        return this.referenceService.getBankById(id);
    }
    async getBanksByType(type) {
        return this.referenceService.getBanksByType(type);
    }
    async getAllCountries() {
        return this.referenceService.getAllCountries();
    }
    async getPopularCountries() {
        return this.referenceService.getPopularCountries();
    }
    async getCountryById(id) {
        return this.referenceService.getCountryById(id);
    }
    async getCountryByCode(code) {
        return this.referenceService.getCountryByCode(code);
    }
    async getCountriesByRegion(region) {
        return this.referenceService.getCountriesByRegion(region);
    }
    async getAllScholarships(country, type, limit, offset) {
        return this.referenceService.getAllScholarships({
            country,
            type,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getScholarshipById(id) {
        return this.referenceService.getScholarshipById(id);
    }
    async getScholarshipsByCountry(country) {
        return this.referenceService.getScholarshipsByCountry(country);
    }
    async getAllCourses(level, field, limit, offset) {
        return this.referenceService.getAllCourses({
            level,
            field,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getPopularCourses() {
        return this.referenceService.getPopularCourses();
    }
    async getCourseById(id) {
        return this.referenceService.getCourseById(id);
    }
    async getCoursesByLevel(level) {
        return this.referenceService.getCoursesByLevel(level);
    }
    async getCoursesByField(field) {
        return this.referenceService.getCoursesByField(field);
    }
};
exports.ReferenceController = ReferenceController;
__decorate([
    (0, common_1.Get)('loan-types'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getAllLoanTypes", null);
__decorate([
    (0, common_1.Get)('loan-types/popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getPopularLoanTypes", null);
__decorate([
    (0, common_1.Get)('loan-types/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getLoanTypeById", null);
__decorate([
    (0, common_1.Get)('universities'),
    __param(0, (0, common_1.Query)('country')),
    __param(1, (0, common_1.Query)('ranking')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getAllUniversities", null);
__decorate([
    (0, common_1.Get)('universities/featured'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getFeaturedUniversities", null);
__decorate([
    (0, common_1.Get)('universities/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getUniversityById", null);
__decorate([
    (0, common_1.Get)('universities/country/:country'),
    __param(0, (0, common_1.Param)('country')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getUniversitiesByCountry", null);
__decorate([
    (0, common_1.Get)('banks'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getAllBanks", null);
__decorate([
    (0, common_1.Get)('banks/popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getPopularBanks", null);
__decorate([
    (0, common_1.Get)('banks/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getBankById", null);
__decorate([
    (0, common_1.Get)('banks/type/:type'),
    __param(0, (0, common_1.Param)('type')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getBanksByType", null);
__decorate([
    (0, common_1.Get)('countries'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getAllCountries", null);
__decorate([
    (0, common_1.Get)('countries/popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getPopularCountries", null);
__decorate([
    (0, common_1.Get)('countries/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getCountryById", null);
__decorate([
    (0, common_1.Get)('countries/code/:code'),
    __param(0, (0, common_1.Param)('code')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getCountryByCode", null);
__decorate([
    (0, common_1.Get)('countries/region/:region'),
    __param(0, (0, common_1.Param)('region')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getCountriesByRegion", null);
__decorate([
    (0, common_1.Get)('scholarships'),
    __param(0, (0, common_1.Query)('country')),
    __param(1, (0, common_1.Query)('type')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getAllScholarships", null);
__decorate([
    (0, common_1.Get)('scholarships/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getScholarshipById", null);
__decorate([
    (0, common_1.Get)('scholarships/country/:country'),
    __param(0, (0, common_1.Param)('country')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getScholarshipsByCountry", null);
__decorate([
    (0, common_1.Get)('courses'),
    __param(0, (0, common_1.Query)('level')),
    __param(1, (0, common_1.Query)('field')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getAllCourses", null);
__decorate([
    (0, common_1.Get)('courses/popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getPopularCourses", null);
__decorate([
    (0, common_1.Get)('courses/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getCourseById", null);
__decorate([
    (0, common_1.Get)('courses/level/:level'),
    __param(0, (0, common_1.Param)('level')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getCoursesByLevel", null);
__decorate([
    (0, common_1.Get)('courses/field/:field'),
    __param(0, (0, common_1.Param)('field')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReferenceController.prototype, "getCoursesByField", null);
exports.ReferenceController = ReferenceController = __decorate([
    (0, common_1.Controller)('reference'),
    __metadata("design:paramtypes", [reference_service_1.ReferenceService])
], ReferenceController);
//# sourceMappingURL=reference.controller.js.map