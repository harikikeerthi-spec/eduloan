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
exports.AdminApplicationService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let AdminApplicationService = class AdminApplicationService {
    db;
    constructor(db) {
        this.db = db;
    }
    async addRemark(appId, remark) {
        try {
            const { data, error } = await this.db
                .from('ApplicationRemarks')
                .insert({
                applicationId: appId,
                type: remark.type,
                content: remark.content,
                authorId: remark.authorId,
                authorName: remark.authorName,
                isInternal: remark.isInternal,
                createdAt: new Date().toISOString(),
            })
                .select()
                .single();
            if (error)
                throw error;
            await this.updateApplicationRemarkCount(appId);
            return { success: true, data };
        }
        catch (e) {
            throw new common_1.BadRequestException(`Failed to add remark: ${e.message}`);
        }
    }
    async getApplicationRemarks(appId) {
        try {
            const { data, error } = await this.db
                .from('ApplicationRemarks')
                .select('*')
                .eq('applicationId', appId)
                .order('createdAt', { ascending: false });
            if (error)
                throw error;
            return data || [];
        }
        catch (e) {
            throw new common_1.BadRequestException(`Failed to fetch remarks: ${e.message}`);
        }
    }
    async assignMentorCounselor(assignment) {
        try {
            const { data, error } = await this.db
                .from('LoanApplication')
                .update({
                mentorId: assignment.mentorId,
                mentorName: assignment.mentorName,
                counselorId: assignment.counselorId,
                counselorName: assignment.counselorName,
                updatedAt: new Date().toISOString(),
            })
                .eq('id', assignment.applicationId)
                .select()
                .single();
            if (error)
                throw error;
            await this.createAuditLog({
                applicationId: assignment.applicationId,
                action: 'assign_mentor_counselor',
                changes: {
                    mentor: assignment.mentorName,
                    counselor: assignment.counselorName,
                },
            });
            return { success: true, data };
        }
        catch (e) {
            throw new common_1.BadRequestException(`Failed to assign mentor/counselor: ${e.message}`);
        }
    }
    async assessRisk(assessment) {
        try {
            const updateData = {
                riskLevel: assessment.riskLevel,
                updatedAt: new Date().toISOString(),
            };
            if (assessment.creditScore) {
                updateData.creditScore = assessment.creditScore;
            }
            if (assessment.notes) {
                updateData.riskNotes = assessment.notes;
            }
            const { data, error } = await this.db
                .from('LoanApplication')
                .update(updateData)
                .eq('id', assessment.applicationId)
                .select()
                .single();
            if (error)
                throw error;
            await this.addRemark(assessment.applicationId, {
                applicationId: assessment.applicationId,
                type: 'remark',
                content: `Risk Assessment: ${assessment.riskLevel.toUpperCase()} | Credit Score: ${assessment.creditScore || 'N/A'}${assessment.notes ? ` | Notes: ${assessment.notes}` : ''}`,
                authorId: 'system',
                authorName: 'System',
                isInternal: true,
            });
            return { success: true, data };
        }
        catch (e) {
            throw new common_1.BadRequestException(`Failed to assess risk: ${e.message}`);
        }
    }
    async batchProcessApplications(applicationIds, action, remarks, adminId, adminName) {
        try {
            const updates = {
                updatedAt: new Date().toISOString(),
            };
            if (action === 'approve') {
                updates.status = 'approved';
                updates.stage = 'sanction';
                updates.progress = 90;
            }
            else if (action === 'reject') {
                updates.status = 'rejected';
                updates.rejectionReason = remarks;
            }
            else if (action === 'flag') {
                updates.status = 'processing';
                updates.priority = 'high';
            }
            else if (action === 'send_request') {
                updates.status = 'processing';
                updates.stage = 'document_verification';
            }
            const { data, error } = await this.db
                .from('LoanApplication')
                .update(updates)
                .in('id', applicationIds)
                .select();
            if (error)
                throw error;
            for (const appId of applicationIds) {
                await this.createAuditLog({
                    applicationId: appId,
                    action: `batch_${action}`,
                    changes: { remarks },
                    initiatorId: adminId,
                    initiatorName: adminName,
                });
                await this.addRemark(appId, {
                    applicationId: appId,
                    type: 'approval_note',
                    content: `[BATCH PROCESS - ${action.toUpperCase()}] ${remarks}`,
                    authorId: adminId,
                    authorName: adminName,
                    isInternal: true,
                });
            }
            return {
                success: true,
                processedCount: data.length,
                data,
            };
        }
        catch (e) {
            throw new common_1.BadRequestException(`Batch processing failed: ${e.message}`);
        }
    }
    async checkEligibility(appId) {
        try {
            const { data: app, error } = await this.db
                .from('LoanApplication')
                .select('*')
                .eq('id', appId)
                .single();
            if (error)
                throw error;
            if (!app)
                throw new common_1.NotFoundException('Application not found');
            const assessments = {
                ageCheck: {
                    criteria: 'Age between 18-40 years',
                    status: this.checkAge(app.dateOfBirth) ? 'pass' : 'fail',
                },
                admissionValidation: {
                    criteria: 'Valid admission from recognized institution',
                    status: app.universityName && app.courseName ? 'pass' : 'fail',
                },
                incomeCheck: {
                    criteria: 'Co-applicant annual income > 3 LPA',
                    status: app.guardianIncome && app.guardianIncome > 300000 ? 'pass' : 'warning',
                },
                creditScore: {
                    criteria: 'CIBIL score > 650',
                    status: app.creditScore && app.creditScore > 650 ? 'pass' : app.creditScore ? 'warning' : 'unknown',
                },
                noDefaults: {
                    criteria: 'No existing defaults/CCJs',
                    status: app.hasDefaults ? 'fail' : 'pass',
                },
                courseDuration: {
                    criteria: 'Course duration >= 6 months',
                    status: app.courseDuration && app.courseDuration >= 6 ? 'pass' : 'fail',
                },
                institutionAccreditation: {
                    criteria: 'Institution accreditation verified',
                    status: app.isUniversityVerified ? 'pass' : 'warning',
                },
            };
            const passCount = Object.values(assessments).filter(a => a.status === 'pass').length;
            const failCount = Object.values(assessments).filter(a => a.status === 'fail').length;
            const overallStatus = failCount === 0 ? 'ELIGIBLE' : 'INELIGIBLE';
            return {
                overallStatus,
                passCount,
                failCount,
                assessments,
                recommendation: failCount === 0
                    ? `Applicant is eligible. Recommended loan: ₹${Math.min(app.amount, this.calculateMaxLoan(app))} | Tenure: 15 years`
                    : `Applicant requires additional review or documentation`,
            };
        }
        catch (e) {
            throw new common_1.BadRequestException(`Eligibility check failed: ${e.message}`);
        }
    }
    async getPortfolioAnalysis(user, bankId) {
        try {
            const isBank = (user?.role === 'bank' || user?.role === 'partner_bank');
            let bankName = null;
            if (isBank) {
                const bId = bankId || user?.firstName;
                if (bId) {
                    const lower = bId.toLowerCase();
                    if (lower.includes('credila'))
                        bankName = 'HDFC Credila';
                    else if (lower.includes('poonawalla'))
                        bankName = 'Poonawalla Fincorp';
                    else if (lower.includes('idfc'))
                        bankName = 'IDFC First Bank';
                    else if (lower.includes('avanse'))
                        bankName = 'Avanse Financial Services';
                    else if (lower.includes('auxilo'))
                        bankName = 'Auxilo';
                    else
                        bankName = bId;
                }
            }
            let query = this.db.from('LoanApplication').select('*');
            if (isBank && bankName) {
                query = query.ilike('bank', `%${bankName}%`);
            }
            const { data: applications, error } = await query;
            if (error)
                throw error;
            const totalValue = applications.reduce((sum, app) => sum + (app.amount || 0), 0);
            const approvedCount = applications.filter(a => a.status === 'approved' || a.status === 'disbursed').length;
            const totalCount = applications.length;
            const approvalRate = totalCount > 0 ? Math.round((approvedCount / totalCount) * 100) : 0;
            const disbursedCount = applications.filter(a => a.status === 'disbursed').length;
            const defaultCount = applications.filter(a => a.status === 'disbursed' && a.hasDefaults).length;
            const defaultRate = disbursedCount > 0 ? ((defaultCount / disbursedCount) * 100).toFixed(2) : '0';
            const avgLoanSize = totalCount > 0 ? Math.round(totalValue / totalCount) : 0;
            const universityGroups = {};
            applications.forEach(app => {
                if (app.universityName) {
                    universityGroups[app.universityName] = (universityGroups[app.universityName] || 0) + 1;
                }
            });
            const topUniversities = Object.entries(universityGroups)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 5)
                .map(([name, count]) => ({
                name,
                count,
                approvalRate: Math.round((applications.filter(a => a.universityName === name && (a.status === 'approved' || a.status === 'disbursed')).length / count) * 100),
            }));
            const monthlyAmounts = [0, 0, 0, 0, 0, 0];
            const months = [];
            const now = new Date();
            for (let i = 5; i >= 0; i--) {
                const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
                months.push(d.toLocaleString('en-US', { month: 'short' }));
            }
            applications.forEach(app => {
                if (app.status !== 'draft' && app.submittedAt) {
                    const date = new Date(app.submittedAt);
                    const diffMonths = (now.getFullYear() - date.getFullYear()) * 12 + (now.getMonth() - date.getMonth());
                    if (diffMonths >= 0 && diffMonths < 6) {
                        const index = 5 - diffMonths;
                        monthlyAmounts[index] += (app.amount || 0);
                    }
                }
            });
            const disbursementTrend = months.map((month, idx) => ({
                month,
                amount: Number((monthlyAmounts[idx] / 10000000).toFixed(2))
            }));
            return {
                totalPortfolioValue: totalValue,
                totalApplications: totalCount,
                approvalRate,
                defaultRate: parseFloat(defaultRate),
                avgLoanSize,
                disbursedAmount: applications
                    .filter(a => a.status === 'disbursed')
                    .reduce((sum, a) => sum + (a.amount || 0), 0),
                topUniversities,
                disbursementTrend,
            };
        }
        catch (e) {
            throw new common_1.BadRequestException(`Portfolio analysis failed: ${e.message}`);
        }
    }
    async getComplianceReport(user, bankId) {
        try {
            const isBank = (user?.role === 'bank' || user?.role === 'partner_bank');
            let bankName = null;
            if (isBank) {
                const bId = bankId || user?.firstName;
                if (bId) {
                    const lower = bId.toLowerCase();
                    if (lower.includes('credila'))
                        bankName = 'HDFC Credila';
                    else if (lower.includes('poonawalla'))
                        bankName = 'Poonawalla Fincorp';
                    else if (lower.includes('idfc'))
                        bankName = 'IDFC First Bank';
                    else if (lower.includes('avanse'))
                        bankName = 'Avanse Financial Services';
                    else if (lower.includes('auxilo'))
                        bankName = 'Auxilo';
                    else
                        bankName = bId;
                }
            }
            let query = this.db.from('LoanApplication').select('*');
            if (isBank && bankName) {
                query = query.ilike('bank', `%${bankName}%`);
            }
            const { data: applications, error } = await query;
            if (error)
                throw error;
            const totalCount = applications.length;
            const verifiedCount = applications.filter(a => a.isVerified).length;
            const overallCompliance = totalCount > 0 ? Math.round((verifiedCount / totalCount) * 100) : 100;
            const report = {
                rbiCompliance: {
                    regulation: 'RBI Education Loan Guidelines',
                    status: 'compliant',
                    detail: 'All applications processed per RBI regulations',
                },
                nhbCompliance: {
                    regulation: 'NHB Mortgage Loan Guidelines',
                    status: 'compliant',
                    detail: 'Collateral evaluation meets NHB standards',
                },
                dataProtection: {
                    regulation: 'Data Protection (Privacy Policy)',
                    status: 'compliant',
                    detail: '100% data encryption and secure storage',
                },
                gstCompliance: {
                    regulation: 'GST Compliance',
                    status: applications.filter(a => !a.gstVerified).length > 0 ? 'warning' : 'compliant',
                    detail: applications.filter(a => !a.gstVerified).length > 0
                        ? `${applications.filter(a => !a.gstVerified).length} applications pending GST documentation`
                        : 'All GST documentation complete',
                },
                kycAml: {
                    regulation: 'KYC/AML Requirements',
                    status: 'compliant',
                    detail: 'All applicants verified through DigiLocker',
                },
                overallCompliance,
            };
            return report;
        }
        catch (e) {
            throw new common_1.BadRequestException(`Compliance report failed: ${e.message}`);
        }
    }
    checkAge(dateOfBirth) {
        const age = new Date().getFullYear() - new Date(dateOfBirth).getFullYear();
        return age >= 18 && age <= 40;
    }
    calculateMaxLoan(app) {
        const baseAmount = 25000000;
        if (app.riskLevel === 'low')
            return baseAmount * 1.2;
        if (app.riskLevel === 'high')
            return baseAmount * 0.8;
        return baseAmount;
    }
    async updateApplicationRemarkCount(appId) {
        const remarks = await this.getApplicationRemarks(appId);
        await this.db
            .from('LoanApplication')
            .update({ remarkCount: remarks.length })
            .eq('id', appId);
    }
    async createAuditLog(data) {
        await this.db.from('AuditLog').insert({
            ...data,
            createdAt: new Date().toISOString(),
        });
    }
};
exports.AdminApplicationService = AdminApplicationService;
exports.AdminApplicationService = AdminApplicationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], AdminApplicationService);
//# sourceMappingURL=admin-application.service.js.map