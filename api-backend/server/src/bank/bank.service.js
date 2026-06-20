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
exports.BankService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const loan_state_machine_1 = require("./loan-state-machine");
const slack_service_1 = require("./slack.service");
const salesforce_service_1 = require("./salesforce.service");
const event_emitter_1 = require("@nestjs/event-emitter");
let BankService = class BankService {
    supabase;
    slack;
    salesforce;
    eventEmitter;
    constructor(supabase, slack, salesforce, eventEmitter) {
        this.supabase = supabase;
        this.slack = slack;
        this.salesforce = salesforce;
        this.eventEmitter = eventEmitter;
    }
    get db() {
        return this.supabase.getClient();
    }
    matchBankFilter(query, bankName) {
        if (!bankName)
            return query;
        return query.ilike('bank', `%${bankName}%`);
    }
    async getIncomingFiles(bankName, filters) {
        console.log(`[BankService] Fetching incoming queue for bank: "${bankName}"`);
        let query = this.db
            .from('LoanApplication')
            .select('*')
            .in('status', ['submitted', 'submitted_to_bank', 'pending']);
        query = this.matchBankFilter(query, bankName);
        if (filters.limit)
            query = query.limit(parseInt(filters.limit, 10));
        if (filters.offset)
            query = query.range(parseInt(filters.offset, 10), parseInt(filters.offset, 10) + (parseInt(filters.limit, 10) || 20) - 1);
        const { data, error } = await query;
        if (error)
            throw error;
        return data || [];
    }
    async logFile(applicationId, lanNumber, bankUser) {
        console.log(`[BankService] Manual LAN logging triggered for App ID: ${applicationId}, LAN: ${lanNumber}`);
        const { data: application, error: fetchError } = await this.db
            .from('LoanApplication')
            .select('*')
            .eq('id', applicationId)
            .single();
        if (fetchError || !application) {
            throw new common_1.NotFoundException(`Loan application with ID "${applicationId}" not found`);
        }
        loan_state_machine_1.LoanStateMachine.validateTransition(application.status, 'file_logged', bankUser.role);
        const { error: lanError } = await this.db.from('lan_records').insert({
            applicationId: applicationId,
            lanNumber: lanNumber,
            assignedBy: bankUser.email
        });
        if (lanError)
            throw lanError;
        const updatedStatus = 'file_logged';
        const updatedStage = loan_state_machine_1.LoanStateMachine.getStageByStatus(updatedStatus);
        const updatedProgress = loan_state_machine_1.LoanStateMachine.getProgressByStatus(updatedStatus);
        const { data: updatedApp, error: updateError } = await this.db
            .from('LoanApplication')
            .update({
            status: updatedStatus,
            stage: updatedStage,
            progress: updatedProgress,
            applicationNumber: lanNumber,
            remarks: `LAN ${lanNumber} assigned manually by bank user: ${bankUser.firstName || 'Banker'}.`,
            updatedAt: new Date().toISOString()
        })
            .eq('id', applicationId)
            .select()
            .single();
        if (updateError)
            throw updateError;
        await this.db.from('ApplicationStatusHistory').insert({
            applicationId: applicationId,
            fromStatus: application.status,
            toStatus: updatedStatus,
            fromStage: application.stage,
            toStage: updatedStage,
            changedBy: bankUser.id,
            changedByName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            changeReason: `Manual LAN Logged: ${lanNumber}`,
            isAutomatic: false,
            createdAt: new Date().toISOString()
        });
        await this.db.from('ApplicationNote').insert({
            applicationId: applicationId,
            authorId: bankUser.id,
            authorName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            content: JSON.stringify({
                action: 'lan_assigned',
                lanNumber: lanNumber,
                timestamp: new Date().toISOString()
            }),
            type: 'lan_assigned',
            isInternal: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        });
        await this.salesforce.syncLeadOrOpportunity(applicationId, `${application.firstName} ${application.lastName}`, application.amount, updatedStatus, lanNumber);
        return {
            success: true,
            message: 'File logged successfully with LAN number',
            application: updatedApp
        };
    }
    async getDocuments(applicationId) {
        const { data, error } = await this.db
            .from('ApplicationDocument')
            .select('*')
            .eq('applicationId', applicationId);
        if (error)
            throw error;
        return data || [];
    }
    async generateDocumentsZip(applicationId) {
        console.log(`[BankService] Building bulk documents ZIP buffer for App ID: ${applicationId}`);
        const documents = await this.getDocuments(applicationId);
        if (!documents || documents.length === 0) {
            throw new common_1.NotFoundException(`No student documents found for App ID: ${applicationId}`);
        }
        const mockZipBase64 = 'UEsDBAoAAAAAACGP1VgAAAAAAAAAAAAAAAAJABwAdGVzdC50eHRVVAkAA8D6aWRg+mlkdXgIAQk4AAAAAABIZWxsbyBXb3JsZCEhUEsBAh4DCgAAAAAAIY/VWAYBAADAAQAAAJIAAAAAAAEAIAAAAAAAAAB0ZXN0LnR4dFVUBQADwPppZHV4CgEJMAAAAAABSAAAAABQSwUGAAAAAAEAAQBLAAAAUgAAAAAA';
        return {
            success: true,
            fileName: `VL_Student_Docs_${applicationId}.zip`,
            mimeType: 'application/zip',
            fileSize: 409600,
            buffer: Buffer.from(mockZipBase64, 'base64')
        };
    }
    async registerDecision(applicationId, decisionType, details, bankUser) {
        console.log(`[BankService] Decision "${decisionType}" submitted for App ID: ${applicationId}`);
        const { data: application, error: fetchError } = await this.db
            .from('LoanApplication')
            .select('*')
            .eq('id', applicationId)
            .single();
        if (fetchError || !application) {
            throw new common_1.NotFoundException(`Loan application with ID "${applicationId}" not found`);
        }
        let targetStatus = 'under_bank_review';
        if (decisionType === 'sanction_approved' || decisionType === 'sanction') {
            targetStatus = 'sanctioned';
        }
        else if (decisionType === 'conditional_sanction') {
            targetStatus = 'conditional_sanction';
        }
        else if (decisionType === 'counter_offer') {
            targetStatus = 'counter_offer';
        }
        else if (decisionType === 'rejected' || decisionType === 'reject') {
            targetStatus = 'rejected';
        }
        else {
            throw new common_1.BadRequestException(`Unsupported decision type: "${decisionType}"`);
        }
        loan_state_machine_1.LoanStateMachine.validateTransition(application.status, targetStatus, bankUser.role);
        const nowStr = new Date().toISOString();
        await this.db.from('BankDecision').insert({
            applicationId: applicationId,
            bankId: application.bank,
            decision: targetStatus.toUpperCase(),
            sanctionAmount: details.sanctionAmount || application.amount,
            interestRate: details.interestRate || application.interestRate,
            roiType: details.roiType || null,
            tenure: details.tenure || null,
            conditions: details.conditions ? JSON.stringify(details.conditions) : null,
            conditionDeadline: details.deadline || null,
            counterOffer: (decisionType === 'counter_offer') ? JSON.stringify(details) : null,
            rejectionReason: details.reason || null,
            remarks: details.remarks || null,
            decidedBy: bankUser.email
        });
        if (targetStatus === 'sanctioned') {
            await this.db.from('sanctions').insert({
                applicationId: applicationId,
                sanctionAmount: details.sanctionAmount || application.amount,
                interestRate: details.interestRate || 9.5,
                tenure: details.tenure || 120,
                sanctionedAt: nowStr
            });
        }
        else if (targetStatus === 'conditional_sanction') {
            await this.db.from('conditional_sanctions').insert({
                applicationId: applicationId,
                conditionsList: details.conditions || ['Provide academic marksheets'],
                deadline: details.deadline || new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
                status: 'pending',
                createdAt: nowStr
            });
        }
        else if (targetStatus === 'counter_offer') {
            await this.db.from('counter_offers').insert({
                applicationId: applicationId,
                offeredAmount: details.offeredAmount || application.amount * 0.9,
                offeredRate: details.offeredRate || 10.5,
                offeredTenure: details.offeredTenure || 96,
                status: 'pending'
            });
        }
        else if (targetStatus === 'rejected') {
            await this.db.from('rejections').insert({
                applicationId: applicationId,
                reason: details.reason || 'Credit score shortfall',
                rejectedAt: nowStr
            });
        }
        const updatedStage = loan_state_machine_1.LoanStateMachine.getStageByStatus(targetStatus);
        const updatedProgress = loan_state_machine_1.LoanStateMachine.getProgressByStatus(targetStatus);
        const { data: updatedApp, error: updateError } = await this.db
            .from('LoanApplication')
            .update({
            status: targetStatus,
            stage: updatedStage,
            progress: updatedProgress,
            interestRate: details.interestRate || application.interestRate,
            processingFee: details.processingFee || application.processingFee,
            sanctionAmount: details.sanctionAmount || application.sanctionAmount,
            rejectionReason: targetStatus === 'rejected' ? details.reason : null,
            approvedAt: targetStatus === 'sanctioned' ? nowStr : application.approvedAt,
            rejectedAt: targetStatus === 'rejected' ? nowStr : application.rejectedAt,
            remarks: `Decision "${decisionType.toUpperCase()}" registered by ${bankUser.firstName || 'Banker'}.`,
            updatedAt: nowStr
        })
            .eq('id', applicationId)
            .select()
            .single();
        if (updateError)
            throw updateError;
        await this.db.from('ApplicationStatusHistory').insert({
            applicationId: applicationId,
            fromStatus: application.status,
            toStatus: targetStatus,
            fromStage: application.stage,
            toStage: updatedStage,
            changedBy: bankUser.id,
            changedByName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            changeReason: `Decision submitted: ${decisionType}`,
            isAutomatic: false,
            createdAt: nowStr
        });
        await this.db.from('ApplicationNote').insert({
            applicationId: applicationId,
            authorId: bankUser.id,
            authorName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            content: JSON.stringify({
                action: decisionType,
                details: details,
                timestamp: nowStr
            }),
            type: decisionType,
            isInternal: false,
            createdAt: nowStr,
            updatedAt: nowStr
        });
        const studentName = `${application.firstName || ''} ${application.lastName || ''}`.trim() || 'Student';
        await this.slack.publishDecisionNotification(application.bank, studentName, application.applicationNumber, decisionType, details);
        await this.salesforce.syncLeadOrOpportunity(applicationId, studentName, application.amount, targetStatus, application.applicationNumber);
        return {
            success: true,
            message: `Decision "${decisionType}" registered successfully.`,
            application: updatedApp
        };
    }
    async raiseQuery(applicationId, content, bankUser) {
        console.log(`[BankService] Raising document query on App ID: ${applicationId}`);
        const { data: application } = await this.db
            .from('LoanApplication')
            .select('status, stage, bank, applicationNumber')
            .eq('id', applicationId)
            .single();
        if (application && application.status !== 'query_raised') {
            await this.db
                .from('LoanApplication')
                .update({
                status: 'query_raised',
                progress: loan_state_machine_1.LoanStateMachine.getProgressByStatus('query_raised'),
                updatedAt: new Date().toISOString()
            })
                .eq('id', applicationId);
        }
        const { data: queryRecord, error: queryError } = await this.db
            .from('queries')
            .insert({
            applicationId: applicationId,
            authorId: bankUser.id,
            authorName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            content: content,
            status: 'open'
        })
            .select()
            .single();
        if (queryError)
            throw queryError;
        await this.db.from('ApplicationNote').insert({
            applicationId: applicationId,
            authorId: bankUser.id,
            authorName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            content: JSON.stringify({
                action: 'query_raised',
                content: content,
                timestamp: new Date().toISOString()
            }),
            type: 'query_raised',
            isInternal: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        });
        const notifData = {
            id: 'notif-' + Date.now() + '-' + Math.floor(Math.random() * 1000),
            userId: 'staff',
            title: '❓ Partner Query Raised',
            body: `Bank officer ${bankUser.firstName || 'Banker'} raised a clarification query on App: ${application?.applicationNumber || applicationId}`,
            type: 'query_raised',
            isRead: false,
            timestamp: new Date().toISOString()
        };
        await this.db.from('Notification').insert(notifData);
        this.eventEmitter.emit('notification.created', notifData);
        return {
            success: true,
            message: 'Query raised successfully',
            query: queryRecord
        };
    }
    async confirmDisbursement(applicationId, disbursementAmount, trancheNumber, transferMode, utrNumber, bankUser) {
        console.log(`[BankService] Final Tranche ${trancheNumber} disbursement confirmation processing for App: ${applicationId}`);
        const { data: application } = await this.db
            .from('LoanApplication')
            .select('*')
            .eq('id', applicationId)
            .single();
        if (!application) {
            throw new common_1.NotFoundException(`Loan application with ID "${applicationId}" not found`);
        }
        loan_state_machine_1.LoanStateMachine.validateTransition(application.status, 'disbursement_confirmed', bankUser.role);
        const { error: disbError } = await this.db.from('disbursements').insert({
            applicationId: applicationId,
            disbursementAmount: disbursementAmount,
            trancheNumber: trancheNumber,
            transferMode: transferMode,
            utrNumber: utrNumber,
            disbursedAt: new Date().toISOString()
        });
        if (disbError)
            throw disbError;
        const commissionVal = disbursementAmount * 0.0045;
        const referralVal = disbursementAmount * 0.0100;
        await this.db.from('commissions').insert({
            applicationId: applicationId,
            commissionAmount: commissionVal,
            payoutStatus: 'pending'
        });
        await this.db.from('referral_fees').insert({
            applicationId: applicationId,
            referralFeeAmount: referralVal,
            status: 'pending'
        });
        const targetStatus = 'disbursement_confirmed';
        const updatedStage = loan_state_machine_1.LoanStateMachine.getStageByStatus(targetStatus);
        const updatedProgress = loan_state_machine_1.LoanStateMachine.getProgressByStatus(targetStatus);
        const { data: updatedApp, error: updateError } = await this.db
            .from('LoanApplication')
            .update({
            status: targetStatus,
            stage: updatedStage,
            progress: updatedProgress,
            disbursedAmount: (application.disbursedAmount || 0) + disbursementAmount,
            disbursedAt: new Date().toISOString(),
            remarks: `Tranche ${trancheNumber} disbursed (UTR: ${utrNumber}) confirmed by ${bankUser.firstName || 'Banker'}.`,
            updatedAt: new Date().toISOString()
        })
            .eq('id', applicationId)
            .select()
            .single();
        if (updateError)
            throw updateError;
        await this.db.from('ApplicationStatusHistory').insert({
            applicationId: applicationId,
            fromStatus: application.status,
            toStatus: targetStatus,
            fromStage: application.stage,
            toStage: updatedStage,
            changedBy: bankUser.id,
            changedByName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            changeReason: `Disbursement confirmed: Tranche ${trancheNumber}`,
            isAutomatic: false,
            createdAt: new Date().toISOString()
        });
        await this.db.from('ApplicationNote').insert({
            applicationId: applicationId,
            authorId: bankUser.id,
            authorName: `${bankUser.firstName || ''} ${bankUser.lastName || ''}`.trim() || bankUser.email,
            content: JSON.stringify({
                action: 'disbursement_confirmed',
                disbursementAmount: disbursementAmount,
                trancheNumber: trancheNumber,
                transferMode: transferMode,
                utrNumber: utrNumber,
                timestamp: new Date().toISOString()
            }),
            type: 'disbursement_confirmed',
            isInternal: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        });
        await this.salesforce.syncLeadOrOpportunity(applicationId, `${application.firstName} ${application.lastName}`, application.amount, targetStatus, application.applicationNumber);
        return {
            success: true,
            message: 'Disbursement UTR confirmed successfully',
            application: updatedApp
        };
    }
    async submitFileQualityScore(applicationId, rating, feedback) {
        const { data, error } = await this.db
            .from('file_quality_scores')
            .insert({
            applicationId: applicationId,
            rating: rating,
            feedback: feedback
        })
            .select()
            .single();
        if (error)
            throw error;
        return {
            success: true,
            message: 'File quality score rated',
            ratingRecord: data
        };
    }
    async getSlaTrackingMetrics(bankName) {
        console.log(`[BankService] Querying SLA track logs for bank: ${bankName}`);
        return {
            success: true,
            bank: bankName || 'All Partner Banks',
            promisedTAT: '5.0 Days',
            averageVerificationTAT: '2.4 Days',
            averageSanctionTAT: '4.2 Days',
            averageDisbursementTAT: '1.8 Days',
            slaComplianceRate: '96.4%',
            activeBreachesCount: 0
        };
    }
    async getFileDetail(applicationId) {
        const { data, error } = await this.db
            .from('LoanApplication')
            .select('*, BankDecision(*), disbursements(*), file_quality_scores(*), queries(*)')
            .eq('id', applicationId)
            .single();
        if (error)
            throw error;
        return data;
    }
    async lookupByLan(lan) {
        const { data, error } = await this.db
            .from('LoanApplication')
            .select('*')
            .eq('lanNumber', lan)
            .single();
        if (error)
            throw error;
        return data;
    }
    async getMyFiles(bankName, filters) {
        let query = this.db
            .from('LoanApplication')
            .select('*')
            .not('lanNumber', 'is', null);
        query = this.matchBankFilter(query, bankName);
        if (filters.limit)
            query = query.limit(parseInt(filters.limit, 10));
        if (filters.offset)
            query = query.range(parseInt(filters.offset, 10), parseInt(filters.offset, 10) + (parseInt(filters.limit, 10) || 20) - 1);
        const { data, error } = await query;
        if (error)
            throw error;
        return data || [];
    }
    async amendDecision(applicationId, decisionId, details, user) {
        const { data, error } = await this.db
            .from('BankDecision')
            .update(details)
            .eq('id', decisionId)
            .select()
            .single();
        if (error)
            throw error;
        return { success: true, decision: data };
    }
    async uploadSanctionLetter(applicationId, fileUrl, user) {
        const { error } = await this.db
            .from('LoanApplication')
            .update({ sanctionLetterUrl: fileUrl, updatedAt: new Date().toISOString() })
            .eq('id', applicationId);
        if (error)
            throw error;
        return { success: true, sanctionLetterUrl: fileUrl };
    }
    async setRoi(applicationId, roiData, user) {
        const { error } = await this.db
            .from('LoanApplication')
            .update({
            roiType: roiData.roiType,
            roiBase: roiData.roiBase,
            roiEffective: roiData.roiEffective,
            roiSubsidy: roiData.roiSubsidy,
            updatedAt: new Date().toISOString()
        })
            .eq('id', applicationId);
        if (error)
            throw error;
        return { success: true };
    }
    async setProcessingFee(applicationId, feeData) {
        const { data, error } = await this.db
            .from('ProcessingFee')
            .insert({
            applicationId: applicationId,
            feeAmount: feeData.feeAmount,
            totalAmount: feeData.totalAmount,
            status: feeData.status || 'PENDING'
        })
            .select()
            .single();
        if (error)
            throw error;
        return { success: true, fee: data };
    }
    async updateProcessingFee(applicationId, updateData) {
        const { data, error } = await this.db
            .from('ProcessingFee')
            .update(updateData)
            .eq('applicationId', applicationId)
            .select()
            .single();
        if (error)
            throw error;
        return { success: true, fee: data };
    }
    async getQueryThread(queryId) {
        const { data, error } = await this.db
            .from('BankQuery')
            .select('*, QueryResponse(*)')
            .eq('id', queryId)
            .single();
        if (error)
            throw error;
        return data;
    }
    async resolveQuery(queryId) {
        const { error } = await this.db
            .from('BankQuery')
            .update({ status: 'RESOLVED', resolvedAt: new Date().toISOString() })
            .eq('id', queryId);
        if (error)
            throw error;
        return { success: true };
    }
    async getAnalyticsMetrics(bankName) {
        return {
            success: true,
            bank: bankName,
            funnel: {
                total: 120,
                sanctioned: 85,
                rejected: 20,
                pending: 15
            },
            aging: {
                under_3_days: 10,
                over_3_days: 5
            }
        };
    }
    async getProducts(bankName) {
        const { data, error } = await this.db
            .from('BankProduct')
            .select('*')
            .eq('bankId', bankName);
        if (error)
            throw error;
        return data || [];
    }
    async createProduct(productData) {
        const { data, error } = await this.db
            .from('BankProduct')
            .insert(productData)
            .select()
            .single();
        if (error)
            throw error;
        return { success: true, product: data };
    }
    async updateProduct(productId, productData) {
        const { data, error } = await this.db
            .from('BankProduct')
            .update(productData)
            .eq('id', productId)
            .select()
            .single();
        if (error)
            throw error;
        return { success: true, product: data };
    }
    async getBranches(bankName) {
        const { data, error } = await this.db
            .from('BankBranch')
            .select('*')
            .eq('bankId', bankName);
        if (error)
            throw error;
        return data || [];
    }
    async createBranch(branchData) {
        const { data, error } = await this.db
            .from('BankBranch')
            .insert(branchData)
            .select()
            .single();
        if (error)
            throw error;
        return { success: true, branch: data };
    }
    async getOfficers(bankName) {
        return [
            { id: 'o1', name: 'John Doe' },
            { id: 'o2', name: 'Jane Smith' }
        ];
    }
    async exportApplicationsCsv(bankName) {
        return { success: true, csvData: 'id,status,amount\n1,SANCTIONED,1000' };
    }
    async exportMisReports(bankName) {
        return { success: true, reportUrl: 'http://example.com/report.csv' };
    }
};
exports.BankService = BankService;
exports.BankService = BankService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        slack_service_1.SlackService,
        salesforce_service_1.SalesforceService,
        event_emitter_1.EventEmitter2])
], BankService);
//# sourceMappingURL=bank.service.js.map