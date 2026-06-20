"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApplicationModule = void 0;
const common_1 = require("@nestjs/common");
const application_controller_1 = require("./application.controller");
const application_service_1 = require("./application.service");
const admin_application_controller_1 = require("./admin-application.controller");
const admin_application_service_1 = require("./admin-application.service");
const auth_module_1 = require("../auth/auth.module");
const ai_module_1 = require("../ai/ai.module");
const integration_module_1 = require("../integration/integration.module");
let ApplicationModule = class ApplicationModule {
};
exports.ApplicationModule = ApplicationModule;
exports.ApplicationModule = ApplicationModule = __decorate([
    (0, common_1.Module)({
        imports: [auth_module_1.AuthModule, ai_module_1.AiModule, integration_module_1.IntegrationModule],
        controllers: [application_controller_1.ApplicationController, admin_application_controller_1.AdminApplicationController],
        providers: [application_service_1.ApplicationService, admin_application_service_1.AdminApplicationService],
        exports: [application_service_1.ApplicationService, admin_application_service_1.AdminApplicationService],
    })
], ApplicationModule);
//# sourceMappingURL=application.module.js.map