"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DocumentModule = void 0;
const common_1 = require("@nestjs/common");
const document_controller_1 = require("./document.controller");
const s3_service_1 = require("./s3.service");
const users_module_1 = require("../users/users.module");
const integration_module_1 = require("../integration/integration.module");
const ai_module_1 = require("../ai/ai.module");
let DocumentModule = class DocumentModule {
};
exports.DocumentModule = DocumentModule;
exports.DocumentModule = DocumentModule = __decorate([
    (0, common_1.Module)({
        imports: [users_module_1.UsersModule, integration_module_1.IntegrationModule, ai_module_1.AiModule],
        controllers: [document_controller_1.DocumentController],
        providers: [s3_service_1.S3Service],
        exports: [s3_service_1.S3Service],
    })
], DocumentModule);
//# sourceMappingURL=document.module.js.map