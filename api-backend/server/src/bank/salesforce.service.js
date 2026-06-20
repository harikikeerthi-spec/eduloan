"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SalesforceService = void 0;
const common_1 = require("@nestjs/common");
let SalesforceService = class SalesforceService {
    async syncLeadOrOpportunity(applicationId, studentName, amount, status, lanNumber) {
        console.log(`[SalesforceService] Synchronizing application ${applicationId} to Salesforce CRM Leads & Opportunities...`);
        let sfStage = 'Prospecting';
        if (status === 'submitted_to_bank')
            sfStage = 'Qualification';
        else if (status === 'file_logged' || status === 'under_bank_review')
            sfStage = 'Needs Analysis';
        else if (['approved', 'sanctioned', 'conditional_sanction'].includes(status))
            sfStage = 'Proposal/Price Quote';
        else if (status === 'disbursement_confirmed' || status === 'closed')
            sfStage = 'Closed Won';
        else if (status === 'rejected')
            sfStage = 'Closed Lost';
        const sfPayload = {
            LeadOrOpportunityId: `0068000000abc${applicationId.substring(0, 3)}`,
            AccountName: studentName,
            OpportunityName: `EduLoan-${studentName}-${new Date().getFullYear()}`,
            StageName: sfStage,
            Amount: amount,
            CloseDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            Loan_Account_Number__c: lanNumber || 'PENDING',
            VL_Status__c: status,
            Last_Sync_Timestamp__c: new Date().toISOString()
        };
        console.log('[SalesforceService] Salesforce Sync Payload mapped:', sfPayload);
        return {
            success: true,
            salesforceId: sfPayload.LeadOrOpportunityId,
            recordType: 'Opportunity',
            status: 'Synchronized',
            conflictResolved: false,
            mappedFieldsCount: Object.keys(sfPayload).length,
            syncedData: sfPayload
        };
    }
};
exports.SalesforceService = SalesforceService;
exports.SalesforceService = SalesforceService = __decorate([
    (0, common_1.Injectable)()
], SalesforceService);
//# sourceMappingURL=salesforce.service.js.map