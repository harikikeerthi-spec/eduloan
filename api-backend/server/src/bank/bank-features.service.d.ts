import { SupabaseService } from '../supabase/supabase.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
export declare class BankFeaturesService {
    private readonly supabase;
    private readonly eventEmitter;
    constructor(supabase: SupabaseService, eventEmitter: EventEmitter2);
    private get db();
    getSchemes(bank?: string, active?: boolean): Promise<any[]>;
    getScheme(schemeId: number): Promise<any>;
    createScheme(schemeData: any, userId: string): Promise<any>;
    updateScheme(schemeId: number, updates: any, userId: string): Promise<any>;
    deleteScheme(schemeId: number, userId: string): Promise<boolean>;
    getExpiringSchemes(daysUntilExpiry?: number): Promise<any[]>;
    autoExpireSchemes(): Promise<{
        expiredCount: number;
    }>;
    getAssignmentRules(): Promise<any[]>;
    createAssignmentRule(ruleData: any, userId: string): Promise<any>;
    updateAssignmentRule(ruleId: number, updates: any): Promise<any>;
    deleteAssignmentRule(ruleId: number): Promise<boolean>;
    triggerAutoAssignment(limit?: number): Promise<{
        assigned: number;
        failed: number;
        errors: Array<{
            appId: string;
            reason: string;
        }>;
    }>;
    private evaluateApplicationForAssignment;
    getAssignmentLogs(applicationId?: string, limit?: number): Promise<any[]>;
    createOfficerTarget(targetData: any, userId: string): Promise<any>;
    getOfficerTarget(targetId: number): Promise<any>;
    updateOfficerTarget(targetId: number, updates: any): Promise<any>;
    getMonthlyTargets(month: string, officerId?: string): Promise<any[]>;
    getOfficerAchievements(officerId: string, month?: string): Promise<any>;
    updateOfficerAchievements(officerId: string, applicationData: any): Promise<void>;
    createRMProfile(profileData: any): Promise<any>;
    getRMProfile(profileId: number): Promise<any>;
    updateRMProfile(profileId: number, updates: any): Promise<any>;
    requestExport(userId: string, exportData: any): Promise<any>;
    getExportJobStatus(jobId: string): Promise<any>;
    processExportJob(jobId: string): Promise<{
        fileUrl: string;
        recordCount: number;
    }>;
    saveColumnPreferences(userId: string, prefData: any): Promise<void>;
    getColumnPreferences(userId: string, jobType: string): Promise<any>;
    cleanupExpiredExports(): Promise<{
        deletedCount: number;
    }>;
    getBranchStatistics(branchCode: string, startDate?: Date, endDate?: Date): Promise<any>;
    getMultibranchReport(startDate?: Date, endDate?: Date): Promise<any>;
    createScheduledReport(reportData: any, userId: string): Promise<any>;
    getScheduledReports(): Promise<any[]>;
    updateScheduledReport(reportId: number, updates: any): Promise<any>;
    triggerReportGeneration(reportId: number): Promise<any>;
    private generateDailySummary;
    private generateWeeklyPipeline;
    private generateMonthlyMIS;
    getReportHistory(limit?: number): Promise<any[]>;
    processScheduledReports(): Promise<{
        processedCount: number;
    }>;
    createStudentRating(ratingData: any, userId: string): Promise<any>;
    getStudentRatings(studentId: string): Promise<any[]>;
    getStudentRatingSummary(studentId: string): Promise<any>;
    private updateRatingAggregates;
    getProductConfigs(bankId?: string): Promise<any[]>;
    createProductConfig(configData: any, userId: string): Promise<any>;
    updateProductConfig(configId: number, updates: any): Promise<any>;
    getChecklistConfigs(bankId?: string, productType?: string): Promise<any[]>;
    createChecklistConfig(configData: any, userId: string): Promise<any>;
    updateChecklistConfig(configId: number, updates: any): Promise<any>;
    getBranchConfigs(bankId?: string): Promise<any[]>;
    getBranchConfig(branchCode: string): Promise<any>;
    createBranchConfig(configData: any, userId: string): Promise<any>;
    updateBranchConfig(configId: number, updates: any): Promise<any>;
}
