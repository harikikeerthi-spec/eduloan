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
exports.MentorGuard = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const supabase_service_1 = require("../supabase/supabase.service");
let MentorGuard = class MentorGuard {
    jwtService;
    supabase;
    constructor(jwtService, supabase) {
        this.jwtService = jwtService;
        this.supabase = supabase;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const token = this.extractTokenFromHeader(request);
        if (!token) {
            throw new common_1.UnauthorizedException('No token provided');
        }
        try {
            const payload = await this.jwtService.verifyAsync(token, {
                secret: process.env.JWT_SECRET || 'your-secret-key',
            });
            if (payload.role !== 'mentor') {
                throw new common_1.UnauthorizedException('Not a mentor account');
            }
            const { data: mentor } = await this.supabase
                .getClient()
                .from('Mentor')
                .select('*')
                .eq('id', payload.mentorId)
                .single();
            if (!mentor || !mentor.isActive || !mentor.isApproved) {
                throw new common_1.UnauthorizedException('Mentor account not active');
            }
            request['mentor'] = {
                id: mentor.id,
                email: mentor.email,
                name: mentor.name,
            };
        }
        catch (error) {
            throw new common_1.UnauthorizedException('Invalid token');
        }
        return true;
    }
    extractTokenFromHeader(request) {
        const [type, token] = request.headers.authorization?.split(' ') ?? [];
        return type === 'Bearer' ? token : undefined;
    }
};
exports.MentorGuard = MentorGuard;
exports.MentorGuard = MentorGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [jwt_1.JwtService,
        supabase_service_1.SupabaseService])
], MentorGuard);
//# sourceMappingURL=mentor.guard.js.map