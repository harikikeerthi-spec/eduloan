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
exports.SalesforceIntegrationController = exports.SalesforceConfigDto = exports.SalesforceAuthDto = exports.SlackIntegrationController = exports.CreateSlackRuleDto = exports.CreateSlackConfigDto = void 0;
const common_1 = require("@nestjs/common");
const staff_guard_1 = require("../auth/staff.guard");
class CreateSlackConfigDto {
    teamId;
    teamName;
    botToken;
    webhookUrl;
    webhookSecret;
    channelMappings;
}
exports.CreateSlackConfigDto = CreateSlackConfigDto;
class CreateSlackRuleDto {
    eventType;
    channelId;
    condition;
    template;
    isEnabled;
}
exports.CreateSlackRuleDto = CreateSlackRuleDto;
let SlackIntegrationController = class SlackIntegrationController {
    async handleSlackWebhook(payload, req) {
        throw new Error('Not implemented');
    }
    async configureSlack(dto, req) {
        throw new Error('Not implemented');
    }
    async createAutoPostRule(dto, req) {
        throw new Error('Not implemented');
    }
    async getAutoPostRules() {
        throw new Error('Not implemented');
    }
    async updateAutoPostRule(dto, req) {
        throw new Error('Not implemented');
    }
    async testSlackIntegration(req) {
        throw new Error('Not implemented');
    }
    async getSlackMessageHistory(limit = 50) {
        throw new Error('Not implemented');
    }
};
exports.SlackIntegrationController = SlackIntegrationController;
__decorate([
    (0, common_1.Post)('webhook'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SlackIntegrationController.prototype, "handleSlackWebhook", null);
__decorate([
    (0, common_1.Post)('config'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CreateSlackConfigDto, Object]),
    __metadata("design:returntype", Promise)
], SlackIntegrationController.prototype, "configureSlack", null);
__decorate([
    (0, common_1.Post)('rules'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CreateSlackRuleDto, Object]),
    __metadata("design:returntype", Promise)
], SlackIntegrationController.prototype, "createAutoPostRule", null);
__decorate([
    (0, common_1.Get)('rules'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SlackIntegrationController.prototype, "getAutoPostRules", null);
__decorate([
    (0, common_1.Put)('rules/:ruleId'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SlackIntegrationController.prototype, "updateAutoPostRule", null);
__decorate([
    (0, common_1.Post)('test'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SlackIntegrationController.prototype, "testSlackIntegration", null);
__decorate([
    (0, common_1.Get)('history'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], SlackIntegrationController.prototype, "getSlackMessageHistory", null);
exports.SlackIntegrationController = SlackIntegrationController = __decorate([
    (0, common_1.Controller)('integration/slack'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard)
], SlackIntegrationController);
class SalesforceAuthDto {
    instanceUrl;
    clientId;
    clientSecret;
    username;
    password;
    securityToken;
}
exports.SalesforceAuthDto = SalesforceAuthDto;
class SalesforceConfigDto {
    fieldMapping;
    autoSync;
    syncInterval;
}
exports.SalesforceConfigDto = SalesforceConfigDto;
let SalesforceIntegrationController = class SalesforceIntegrationController {
    async authenticateSalesforce(dto, req) {
        throw new Error('Not implemented');
    }
    async configureSalesforce(dto, req) {
        throw new Error('Not implemented');
    }
    async triggerSalesforceSync(req, objectType) {
        throw new Error('Not implemented');
    }
    async getSyncStatus() {
        throw new Error('Not implemented');
    }
    async getSyncAuditLogs(limit = 50, objectType) {
        throw new Error('Not implemented');
    }
    async testSalesforceConnection() {
        throw new Error('Not implemented');
    }
};
exports.SalesforceIntegrationController = SalesforceIntegrationController;
__decorate([
    (0, common_1.Post)('auth'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [SalesforceAuthDto, Object]),
    __metadata("design:returntype", Promise)
], SalesforceIntegrationController.prototype, "authenticateSalesforce", null);
__decorate([
    (0, common_1.Post)('config'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [SalesforceConfigDto, Object]),
    __metadata("design:returntype", Promise)
], SalesforceIntegrationController.prototype, "configureSalesforce", null);
__decorate([
    (0, common_1.Post)('sync'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('objectType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], SalesforceIntegrationController.prototype, "triggerSalesforceSync", null);
__decorate([
    (0, common_1.Get)('status'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SalesforceIntegrationController.prototype, "getSyncStatus", null);
__decorate([
    (0, common_1.Get)('audit'),
    __param(0, (0, common_1.Query)('limit')),
    __param(1, (0, common_1.Query)('objectType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, String]),
    __metadata("design:returntype", Promise)
], SalesforceIntegrationController.prototype, "getSyncAuditLogs", null);
__decorate([
    (0, common_1.Post)('test'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SalesforceIntegrationController.prototype, "testSalesforceConnection", null);
exports.SalesforceIntegrationController = SalesforceIntegrationController = __decorate([
    (0, common_1.Controller)('integration/salesforce'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard)
], SalesforceIntegrationController);
//# sourceMappingURL=integration.controller-f26-f27.js.map