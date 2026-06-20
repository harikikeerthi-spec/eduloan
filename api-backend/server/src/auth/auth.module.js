"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthModule = void 0;
const common_1 = require("@nestjs/common");
const auth_service_1 = require("./auth.service");
const users_module_1 = require("../users/users.module");
const email_service_1 = require("./email.service");
const auth_controller_1 = require("./auth.controller");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const admin_guard_1 = require("./admin.guard");
const super_admin_guard_1 = require("./super-admin.guard");
const staff_guard_1 = require("./staff.guard");
const authorization_service_1 = require("./authorization.service");
const audit_log_service_1 = require("./audit-log.service");
const user_guard_1 = require("./user.guard");
const referral_module_1 = require("../referral/referral.module");
const event_emitter_1 = require("@nestjs/event-emitter");
const firebase_auth_service_1 = require("./firebase-auth.service");
let AuthModule = class AuthModule {
};
exports.AuthModule = AuthModule;
exports.AuthModule = AuthModule = __decorate([
    (0, common_1.Module)({
        imports: [
            event_emitter_1.EventEmitterModule,
            (0, common_1.forwardRef)(() => referral_module_1.ReferralModule),
            users_module_1.UsersModule,
            config_1.ConfigModule,
            jwt_1.JwtModule.registerAsync({
                imports: [config_1.ConfigModule],
                useFactory: async (configService) => ({
                    secret: (configService.get('JWT_SECRET') || 'secretKey'),
                    signOptions: {
                        expiresIn: (configService.get('JWT_ACCESS_TOKEN_EXPIRATION') || configService.get('JWT_EXPIRATION') || '30m'),
                    },
                }),
                inject: [config_1.ConfigService],
            }),
        ],
        controllers: [auth_controller_1.AuthController],
        providers: [
            auth_service_1.AuthService,
            email_service_1.EmailService,
            admin_guard_1.AdminGuard,
            super_admin_guard_1.SuperAdminGuard,
            staff_guard_1.StaffGuard,
            authorization_service_1.AuthorizationService,
            audit_log_service_1.AuditLogService,
            user_guard_1.UserGuard,
            firebase_auth_service_1.FirebaseAuthService,
        ],
        exports: [
            auth_service_1.AuthService,
            jwt_1.JwtModule,
            users_module_1.UsersModule,
            admin_guard_1.AdminGuard,
            super_admin_guard_1.SuperAdminGuard,
            staff_guard_1.StaffGuard,
            authorization_service_1.AuthorizationService,
            audit_log_service_1.AuditLogService,
            user_guard_1.UserGuard,
            email_service_1.EmailService,
            firebase_auth_service_1.FirebaseAuthService,
        ],
    })
], AuthModule);
//# sourceMappingURL=auth.module.js.map