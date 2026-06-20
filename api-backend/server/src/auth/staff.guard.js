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
exports.StaffGuard = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const users_service_1 = require("../users/users.service");
let StaffGuard = class StaffGuard {
    jwtService;
    usersService;
    constructor(jwtService, usersService) {
        this.jwtService = jwtService;
        this.usersService = usersService;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const authHeader = request.headers.authorization;
        let token;
        if (authHeader) {
            const [type, tokenStr] = authHeader.split(' ');
            if (type !== 'Bearer' || !tokenStr) {
                throw new common_1.UnauthorizedException('Invalid authorization format');
            }
            token = tokenStr;
        }
        else if (request.query.token) {
            token = request.query.token;
        }
        if (!token) {
            throw new common_1.UnauthorizedException('No authorization token provided');
        }
        try {
            const payload = await this.jwtService.verifyAsync(token);
            console.log('[StaffGuard] Token verified. Payload:', { email: payload.email, role: payload.role });
            const user = await this.usersService.findOne(payload.email);
            if (!user) {
                console.error('[StaffGuard] User not found in DB for email:', payload.email);
                throw new common_1.UnauthorizedException('User not found');
            }
            const allowedRoles = ['staff', 'admin', 'super_admin', 'bank', 'partner_bank'];
            if (!allowedRoles.includes(user.role)) {
                console.warn(`[StaffGuard] Access denied for role: ${user.role}. User: ${user.email}`);
                throw new common_1.ForbiddenException('Access denied. Elevated privileges required.');
            }
            request.user = user;
            console.log(`[StaffGuard] Access granted to ${user.email} (${user.role})`);
            return true;
        }
        catch (error) {
            console.error('[StaffGuard] Error:', error.message || error);
            if (error instanceof common_1.ForbiddenException || error instanceof common_1.UnauthorizedException) {
                throw error;
            }
            if (error.name === 'TokenExpiredError') {
                throw new common_1.UnauthorizedException({
                    message: 'Token has expired',
                    error: 'Unauthorized',
                    statusCode: 401,
                    hint: 'Please use the /auth/refresh endpoint with your refresh_token to get a new access token'
                });
            }
            throw new common_1.UnauthorizedException('Invalid token');
        }
    }
};
exports.StaffGuard = StaffGuard;
exports.StaffGuard = StaffGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [jwt_1.JwtService,
        users_service_1.UsersService])
], StaffGuard);
//# sourceMappingURL=staff.guard.js.map