"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BankModule = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const supabase_module_1 = require("../supabase/supabase.module");
const users_module_1 = require("../users/users.module");
const bank_controller_1 = require("./bank.controller");
const bank_service_1 = require("./bank.service");
const bank_dashboard_controller_1 = require("./bank-dashboard.controller");
const bank_dashboard_service_1 = require("./bank-dashboard.service");
const bank_workflow_controller_1 = require("./bank-workflow.controller");
const bank_workflow_service_1 = require("./bank-workflow.service");
const slack_service_1 = require("./slack.service");
const salesforce_service_1 = require("./salesforce.service");
const bank_cron_service_1 = require("./bank-cron.service");
const bank_rbac_middleware_1 = require("./bank-rbac.middleware");
let BankModule = class BankModule {
};
exports.BankModule = BankModule;
exports.BankModule = BankModule = __decorate([
    (0, common_1.Module)({
        imports: [
            supabase_module_1.SupabaseModule,
            users_module_1.UsersModule,
            jwt_1.JwtModule.register({
                secret: process.env.JWT_SECRET || 'secretKey',
                signOptions: { expiresIn: '7d' },
            }),
        ],
        controllers: [bank_controller_1.BankController, bank_dashboard_controller_1.BankDashboardController, bank_workflow_controller_1.BankWorkflowController],
        providers: [
            bank_service_1.BankService,
            bank_dashboard_service_1.BankDashboardService,
            bank_workflow_service_1.BankWorkflowService,
            slack_service_1.SlackService,
            salesforce_service_1.SalesforceService,
            bank_cron_service_1.BankCronService,
            bank_rbac_middleware_1.BankRbacInterceptor
        ],
        exports: [bank_service_1.BankService, bank_dashboard_service_1.BankDashboardService, bank_workflow_service_1.BankWorkflowService, bank_cron_service_1.BankCronService]
    })
], BankModule);
//# sourceMappingURL=bank.module.js.map