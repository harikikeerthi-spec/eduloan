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
exports.BankCronService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const salesforce_service_1 = require("./salesforce.service");
let BankCronService = class BankCronService {
    supabase;
    salesforce;
    constructor(supabase, salesforce) {
        this.supabase = supabase;
        this.salesforce = salesforce;
    }
    get db() {
        return this.supabase.getClient();
    }
    async checkSanctionExpiries() {
        console.log('[Cron: ExpiryCheck] Scanning for inactive sanctions older than 30 days...');
        try {
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
            const { data: activeSanctions, error } = await this.db
                .from('LoanApplication')
                .select('id, applicationNumber, status, bank, amount, firstName, lastName, updatedAt')
                .in('status', ['approved', 'sanctioned', 'conditional_sanction', 'partial_sanction', 'counter_offer'])
                .lt('updatedAt', thirtyDaysAgo.toISOString());
            if (error)
                throw error;
            if (!activeSanctions || activeSanctions.length === 0) {
                console.log('[Cron: ExpiryCheck] Zero expired sanctions detected today.');
                return;
            }
            console.log(`[Cron: ExpiryCheck] Detected ${activeSanctions.length} expired sanctions. Transitioning to EXPIRED...`);
            for (const app of activeSanctions) {
                const ageDays = Math.floor((Date.now() - new Date(app.updatedAt).getTime()) / (1000 * 60 * 60 * 24));
                await this.db
                    .from('LoanApplication')
                    .update({
                    status: 'expired',
                    remarks: `Auto-lapsed: Sanction validity of 30 days exceeded (${ageDays} days elapsed).`,
                    updatedAt: new Date().toISOString()
                })
                    .eq('id', app.id);
                await this.db.from('ApplicationStatusHistory').insert({
                    applicationId: app.id,
                    fromStatus: app.status,
                    toStatus: 'expired',
                    changedBy: 'system_cron',
                    changedByName: 'VidyaLoans Cron Engine',
                    changeReason: `Sanction 30-day validity elapsed (${ageDays} days). Auto-lapsed.`,
                    isAutomatic: true,
                    createdAt: new Date().toISOString()
                });
                await this.db.from('queries').insert({
                    applicationId: app.id,
                    authorName: 'SLA Expiry Monitor',
                    content: `🚨 EXPIRED: Sanction for ${app.firstName} ${app.lastName} (${app.applicationNumber || app.id}) has auto-lapsed after ${ageDays} days. Re-verification required.`,
                    status: 'open',
                    createdAt: new Date().toISOString()
                });
                console.log(`[Cron: ExpiryCheck] Auto-lapsed App ${app.applicationNumber || app.id} (${ageDays} days old).`);
            }
        }
        catch (err) {
            console.error('[Cron: ExpiryCheck] Error running cron:', err.message);
        }
    }
    async checkSanctionExpiryWarnings() {
        console.log('[Cron: ExpiryWarning] Scanning for sanctions expiring within 7 days...');
        try {
            const twentyThreeDaysAgo = new Date();
            twentyThreeDaysAgo.setDate(twentyThreeDaysAgo.getDate() - 23);
            const twentyNineDaysAgo = new Date();
            twentyNineDaysAgo.setDate(twentyNineDaysAgo.getDate() - 29);
            const { data: nearExpiryApps, error } = await this.db
                .from('LoanApplication')
                .select('id, applicationNumber, status, bank, amount, firstName, lastName, updatedAt')
                .in('status', ['approved', 'sanctioned', 'conditional_sanction', 'partial_sanction', 'counter_offer'])
                .lt('updatedAt', twentyThreeDaysAgo.toISOString())
                .gte('updatedAt', twentyNineDaysAgo.toISOString());
            if (error)
                throw error;
            if (!nearExpiryApps || nearExpiryApps.length === 0) {
                console.log('[Cron: ExpiryWarning] No sanctions nearing expiry.');
                return;
            }
            console.log(`[Cron: ExpiryWarning] ${nearExpiryApps.length} sanction(s) expiring within 7 days.`);
            for (const app of nearExpiryApps) {
                const ageDays = Math.floor((Date.now() - new Date(app.updatedAt).getTime()) / (1000 * 60 * 60 * 24));
                const daysRemaining = 30 - ageDays;
                await this.db.from('Notification').insert({
                    userId: 'system',
                    title: `⚠️ Sanction Expiry Warning: ${app.firstName} ${app.lastName}`,
                    message: `Sanction for ${app.firstName} ${app.lastName} (${app.applicationNumber || app.id}, ₹${app.amount?.toLocaleString('en-IN') || 'N/A'}) at ${app.bank} will auto-lapse in ${daysRemaining} day(s). Please initiate disbursement.`,
                    type: 'sanction_expiry_warning',
                    isRead: false,
                    metadata: { applicationId: app.id, daysRemaining, ageDays },
                    createdAt: new Date().toISOString()
                });
                console.log(`[Cron: ExpiryWarning] Warning sent for App ${app.applicationNumber || app.id} — ${daysRemaining} day(s) remaining.`);
            }
        }
        catch (err) {
            console.error('[Cron: ExpiryWarning] Error running warning cron:', err.message);
        }
    }
    async checkSlaBreaches() {
        console.log('[Cron: SlaBreach] Scanning for SLA timeline breaches...');
        try {
            const fiveDaysAgo = new Date();
            fiveDaysAgo.setDate(fiveDaysAgo.getDate() - 5);
            const { data: stuckApps, error } = await this.db
                .from('LoanApplication')
                .select('id, applicationNumber, status, bank, updatedAt, firstName, lastName')
                .in('status', ['submitted_to_bank', 'file_logged', 'under_bank_review', 'query_raised'])
                .lt('updatedAt', fiveDaysAgo.toISOString());
            if (error)
                throw error;
            if (!stuckApps || stuckApps.length === 0) {
                console.log('[Cron: SlaBreach] Zero SLA breaches detected.');
                return;
            }
            console.log(`[Cron: SlaBreach] Detected ${stuckApps.length} SLA breach alerts! Pushing notifications...`);
            for (const app of stuckApps) {
                await this.db.from('sla_metrics').insert({
                    applicationId: app.id,
                    stage: app.status,
                    tatDays: 5.0,
                    slaMet: false,
                    createdAt: new Date().toISOString()
                });
                await this.db.from('Notification').insert({
                    userId: 'system',
                    title: `⚠️ SLA Breach Alert: App ${app.applicationNumber}`,
                    message: `Application for ${app.firstName} ${app.lastName} has exceeded the promised 5-day review TAT at partner bank: ${app.bank}.`,
                    type: 'sla_breach',
                    isRead: false,
                    createdAt: new Date().toISOString()
                });
                console.log(`[Cron: SlaBreach] SLA breach flagged on App ${app.applicationNumber} (${app.bank})`);
            }
        }
        catch (err) {
            console.error('[Cron: SlaBreach] Error running SLA check:', err.message);
        }
    }
    async autoSalesforceSync() {
        console.log('[Cron: SalesforceSync] Running periodic lead & opportunity sync...');
        try {
            const { data: recentApps, error } = await this.db
                .from('LoanApplication')
                .select('id, firstName, lastName, amount, status, applicationNumber')
                .limit(10);
            if (error)
                throw error;
            for (const app of recentApps) {
                const studentName = `${app.firstName || ''} ${app.lastName || ''}`.trim() || 'Student';
                await this.salesforce.syncLeadOrOpportunity(app.id, studentName, app.amount || 100000, app.status, app.applicationNumber);
            }
            console.log('[Cron: SalesforceSync] Sync completed.');
        }
        catch (err) {
            console.error('[Cron: SalesforceSync] Error running Salesforce Sync Cron:', err.message);
        }
    }
    async checkQuerySlaTimers() {
        console.log('[Cron: QuerySLA] Scanning for pending queries SLA status...');
        try {
            const { data: pendingQueries, error } = await this.db
                .from('BankWorkflowQueryRequest')
                .select('*')
                .eq('status', 'PENDING');
            if (error)
                throw error;
            if (!pendingQueries || pendingQueries.length === 0) {
                console.log('[Cron: QuerySLA] Zero pending queries detected.');
                return;
            }
            const now = new Date();
            for (const query of pendingQueries) {
                const { data: submission, error: subError } = await this.db
                    .from('BankSubmission')
                    .select('isOnHold, slaPausedDurationMs, bankName')
                    .eq('id', query.submissionId)
                    .single();
                if (subError || !submission) {
                    console.warn(`[Cron: QuerySLA] Submission not found for query ${query.id}`);
                    continue;
                }
                if (submission.isOnHold) {
                    console.log(`[Cron: QuerySLA] Query ${query.id} is paused (Submission ${query.submissionId} is ON HOLD). Skipping.`);
                    continue;
                }
                const raisedAt = new Date(query.raisedAt);
                const pausedMs = parseInt(submission.slaPausedDurationMs || '0', 10);
                const elapsedMs = now.getTime() - raisedAt.getTime() - pausedMs;
                const elapsedHours = elapsedMs / 1000 / 60 / 60;
                console.log(`[Cron: QuerySLA] Query ${query.id} elapsed: ${Math.round(elapsedHours)} hours.`);
                if (elapsedHours >= 72) {
                    const { data: exists } = await this.db
                        .from('Notification')
                        .select('id')
                        .eq('type', 'query_sla_mgmt_escalate')
                        .eq('metadata->>queryId', query.id)
                        .maybeSingle();
                    if (!exists) {
                        await this.db.from('Notification').insert({
                            userId: 'system',
                            title: `🚨 Query SLA Management Escalation (72h)`,
                            message: `CRITICAL: Pending query of type "${query.queryType}" raised by ${submission.bankName} has exceeded 72 hours without response. Immediate management intervention required.`,
                            type: 'query_sla_mgmt_escalate',
                            isRead: false,
                            metadata: { queryId: query.id, submissionId: query.submissionId, elapsedHours },
                            createdAt: now.toISOString()
                        });
                        console.log(`[Cron: QuerySLA] Escalated query ${query.id} to Management.`);
                    }
                }
                else if (elapsedHours >= 48) {
                    const { data: exists } = await this.db
                        .from('Notification')
                        .select('id')
                        .eq('type', 'query_sla_admin_escalate')
                        .eq('metadata->>queryId', query.id)
                        .maybeSingle();
                    if (!exists) {
                        await this.db.from('Notification').insert({
                            userId: 'system',
                            title: `⚠️ Query SLA Admin Escalation (48h)`,
                            message: `WARNING: Pending query of type "${query.queryType}" raised by ${submission.bankName} has exceeded 48 hours. Escalated to administrator.`,
                            type: 'query_sla_admin_escalate',
                            isRead: false,
                            metadata: { queryId: query.id, submissionId: query.submissionId, elapsedHours },
                            createdAt: now.toISOString()
                        });
                        console.log(`[Cron: QuerySLA] Escalated query ${query.id} to Admin.`);
                    }
                }
                else if (elapsedHours >= 24) {
                    const { data: exists } = await this.db
                        .from('Notification')
                        .select('id')
                        .eq('type', 'query_sla_reminder')
                        .eq('metadata->>queryId', query.id)
                        .maybeSingle();
                    if (!exists) {
                        await this.db.from('Notification').insert({
                            userId: 'system',
                            title: `⏰ Query SLA Reminder (24h)`,
                            message: `Reminder: There is a pending query of type "${query.queryType}" raised by ${submission.bankName} that requires response.`,
                            type: 'query_sla_reminder',
                            isRead: false,
                            metadata: { queryId: query.id, submissionId: query.submissionId, elapsedHours },
                            createdAt: now.toISOString()
                        });
                        console.log(`[Cron: QuerySLA] Sent 24h reminder for query ${query.id}.`);
                    }
                }
            }
        }
        catch (err) {
            console.error('[Cron: QuerySLA] Error running query SLA cron:', err.message);
        }
    }
};
exports.BankCronService = BankCronService;
exports.BankCronService = BankCronService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        salesforce_service_1.SalesforceService])
], BankCronService);
//# sourceMappingURL=bank-cron.service.js.map