"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UniversityModule = void 0;
const common_1 = require("@nestjs/common");
const university_inquiry_controller_1 = require("./university-inquiry.controller");
const university_inquiry_service_1 = require("./university-inquiry.service");
const email_service_1 = require("../auth/email.service");
let UniversityModule = class UniversityModule {
};
exports.UniversityModule = UniversityModule;
exports.UniversityModule = UniversityModule = __decorate([
    (0, common_1.Module)({
        controllers: [university_inquiry_controller_1.UniversityInquiryController],
        providers: [university_inquiry_service_1.UniversityInquiryService, email_service_1.EmailService],
    })
], UniversityModule);
//# sourceMappingURL=university.module.js.map