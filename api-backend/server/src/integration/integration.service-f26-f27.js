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
exports.SalesforceIntegrationService = exports.SlackIntegrationService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const event_emitter_1 = require("@nestjs/event-emitter");
let SlackIntegrationService = class SlackIntegrationService {
    supabase;
    eventEmitter;
    constructor(supabase, eventEmitter) {
        this.supabase = supabase;
        this.eventEmitter = eventEmitter;
    }
    get db() {
        return this.supabase.getClient();
    }
    async handleWebhookEvent(payload, signature) {
        console.log(`[SlackIntegrationService] Handling webhook event`);
        throw new Error('Not implemented');
    }
    async configureIntegration(config, userId) {
        console.log(`[SlackIntegrationService] Configuring Slack by user ${userId}`);
        throw new Error('Not implemented');
    }
    async createAutoPostRule(ruleData) {
        console.log(`[SlackIntegrationService] Creating auto-post rule`);
        throw new Error('Not implemented');
    }
    async getAutoPostRules() {
        console.log(`[SlackIntegrationService] Fetching auto-post rules`);
        throw new Error('Not implemented');
    }
    async postToSlack(channelId, message, template) {
        console.log(`[SlackIntegrationService] Posting message to Slack channel ${channelId}`);
        throw new Error('Not implemented');
    }
    async autoPostDecisionOrQuery(sourceType, sourceData) {
        console.log(`[SlackIntegrationService] Auto-posting ${sourceType} to Slack`);
        throw new Error('Not implemented');
    }
    async testIntegration() {
        console.log(`[SlackIntegrationService] Testing Slack integration`);
        throw new Error('Not implemented');
    }
    async getMessageHistory(limit = 50) {
        console.log(`[SlackIntegrationService] Fetching message history`);
        throw new Error('Not implemented');
    }
    verifyWebhookSignature(body, signature, timestamp) {
        console.log(`[SlackIntegrationService] Verifying webhook signature`);
        throw new Error('Not implemented');
    }
};
exports.SlackIntegrationService = SlackIntegrationService;
exports.SlackIntegrationService = SlackIntegrationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        event_emitter_1.EventEmitter2])
], SlackIntegrationService);
let SalesforceIntegrationService = class SalesforceIntegrationService {
    supabase;
    eventEmitter;
    constructor(supabase, eventEmitter) {
        this.supabase = supabase;
        this.eventEmitter = eventEmitter;
    }
    get db() {
        return this.supabase.getClient();
    }
    async authenticateSalesforce(authData) {
        console.log(`[SalesforceIntegrationService] Authenticating with Salesforce`);
        throw new Error('Not implemented');
    }
    async getAccessToken() {
        console.log(`[SalesforceIntegrationService] Getting Salesforce access token`);
        throw new Error('Not implemented');
    }
    async triggerSync(objectType) {
        console.log(`[SalesforceIntegrationService] Triggering Salesforce sync (type: ${objectType})`);
        throw new Error('Not implemented');
    }
    async syncUserToSalesforce(userId, userData) {
        console.log(`[SalesforceIntegrationService] Syncing user ${userId} to Salesforce`);
        throw new Error('Not implemented');
    }
    async syncApplicationToSalesforce(applicationId, appData) {
        console.log(`[SalesforceIntegrationService] Syncing application ${applicationId} to Salesforce`);
        throw new Error('Not implemented');
    }
    async getSyncStatus() {
        console.log(`[SalesforceIntegrationService] Getting sync status`);
        throw new Error('Not implemented');
    }
    async getSyncAuditLogs(limit = 50, objectType) {
        console.log(`[SalesforceIntegrationService] Fetching sync audit logs`);
        throw new Error('Not implemented');
    }
    async testConnection() {
        console.log(`[SalesforceIntegrationService] Testing Salesforce connection`);
        throw new Error('Not implemented');
    }
    async retryFailedSyncs() {
        console.log(`[SalesforceIntegrationService] Retrying failed syncs`);
        throw new Error('Not implemented');
    }
    async autoSyncApplicationStatusChange(applicationId, newStatus) {
        console.log(`[SalesforceIntegrationService] Auto-syncing application status change`);
        throw new Error('Not implemented');
    }
    mapApplicationToOpportunity(appData) {
        console.log(`[SalesforceIntegrationService] Mapping application to Opportunity`);
        throw new Error('Not implemented');
    }
};
exports.SalesforceIntegrationService = SalesforceIntegrationService;
exports.SalesforceIntegrationService = SalesforceIntegrationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        event_emitter_1.EventEmitter2])
], SalesforceIntegrationService);
//# sourceMappingURL=integration.service-f26-f27.js.map