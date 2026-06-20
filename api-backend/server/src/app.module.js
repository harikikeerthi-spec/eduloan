"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const event_emitter_1 = require("@nestjs/event-emitter");
const app_controller_1 = require("./app.controller");
const app_service_1 = require("./app.service");
const auth_module_1 = require("./auth/auth.module");
const users_module_1 = require("./users/users.module");
const supabase_module_1 = require("./supabase/supabase.module");
const blog_module_1 = require("./blog/blog.module");
const document_module_1 = require("./document/document.module");
const ai_module_1 = require("./ai/ai.module");
const community_module_1 = require("./community/community.module");
const reference_module_1 = require("./reference/reference.module");
const application_module_1 = require("./application/application.module");
const explore_module_1 = require("./explore/explore.module");
const onboarding_module_1 = require("./onboarding/onboarding.module");
const integration_module_1 = require("./integration/integration.module");
const audit_module_1 = require("./audit/audit.module");
const referral_module_1 = require("./referral/referral.module");
const connected_module_1 = require("./connected/connected.module");
const university_module_1 = require("./university/university.module");
const chat_module_1 = require("./chat/chat.module");
const staff_profile_module_1 = require("./staff-profile/staff-profile.module");
const bank_module_1 = require("./bank/bank.module");
const notification_module_1 = require("./notification/notification.module");
const serve_static_1 = require("@nestjs/serve-static");
const path_1 = require("path");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            event_emitter_1.EventEmitterModule.forRoot(),
            serve_static_1.ServeStaticModule.forRoot({
                rootPath: (0, path_1.join)(__dirname, '..', 'uploads'),
                serveRoot: '/uploads',
            }),
            supabase_module_1.SupabaseModule,
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            blog_module_1.BlogModule,
            document_module_1.DocumentModule,
            ai_module_1.AiModule,
            community_module_1.CommunityModule,
            reference_module_1.ReferenceModule,
            application_module_1.ApplicationModule,
            explore_module_1.ExploreModule,
            onboarding_module_1.OnboardingModule,
            integration_module_1.IntegrationModule,
            audit_module_1.AuditModule,
            referral_module_1.ReferralModule,
            connected_module_1.ConnectedModule,
            university_module_1.UniversityModule,
            chat_module_1.ChatModule,
            staff_profile_module_1.StaffProfileModule,
            bank_module_1.BankModule,
            notification_module_1.NotificationModule,
        ],
        controllers: [app_controller_1.AppController],
        providers: [app_service_1.AppService],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map