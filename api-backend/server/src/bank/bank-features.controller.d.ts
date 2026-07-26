import { CreateBankSchemeDto, BankSchemeResponseDto, CreateAssignmentRuleDto, AssignmentRuleResponseDto, AssignmentLogDto, CreateOfficerTargetDto, OfficerTargetResponseDto, CreateRMProfileDto, RMProfileResponseDto, CreateExportJobDto, ExportJobResponseDto, CreateScheduledReportDto, ScheduledReportResponseDto, ReportRunDto, CreateStudentRatingDto, StudentRatingResponseDto, CreateProductConfigDto, ProductConfigResponseDto, CreateChecklistConfigDto, ChecklistConfigResponseDto, CreateBranchConfigDto, BranchConfigResponseDto, BranchStatisticsDto, MultibranchReportDto } from './dto/bank-features.dto';
export declare class BankFeaturesController {
    getSchemes(bank?: string, active?: boolean): Promise<BankSchemeResponseDto[]>;
    getScheme(schemeId: number): Promise<BankSchemeResponseDto>;
    createScheme(dto: CreateBankSchemeDto, req: any): Promise<BankSchemeResponseDto>;
    updateScheme(schemeId: number, dto: Partial<CreateBankSchemeDto>, req: any): Promise<BankSchemeResponseDto>;
    deleteScheme(schemeId: number, req: any): Promise<{
        success: boolean;
    }>;
    getExpiringSchemes(daysUntilExpiry?: number): Promise<BankSchemeResponseDto[]>;
    getAssignmentRules(): Promise<AssignmentRuleResponseDto[]>;
    createAssignmentRule(dto: CreateAssignmentRuleDto, req: any): Promise<AssignmentRuleResponseDto>;
    updateAssignmentRule(ruleId: number, dto: Partial<CreateAssignmentRuleDto>, req: any): Promise<AssignmentRuleResponseDto>;
    deleteAssignmentRule(ruleId: number, req: any): Promise<{
        success: boolean;
    }>;
    triggerAutoAssignment(req: any, limit?: number): Promise<{
        assigned: number;
        failed: number;
    }>;
    getAssignmentLogs(applicationId?: string, limit?: number): Promise<AssignmentLogDto[]>;
    createOfficerTarget(dto: CreateOfficerTargetDto, req: any): Promise<OfficerTargetResponseDto>;
    getOfficerTarget(targetId: number): Promise<OfficerTargetResponseDto>;
    updateOfficerTarget(targetId: number, dto: Partial<CreateOfficerTargetDto>, req: any): Promise<OfficerTargetResponseDto>;
    getMonthlyTargets(month: string, officerId?: string): Promise<OfficerTargetResponseDto[]>;
    getOfficerAchievements(officerId: string, month?: string): Promise<any>;
    createRMProfile(dto: CreateRMProfileDto, req: any): Promise<RMProfileResponseDto>;
    getRMProfile(profileId: number): Promise<RMProfileResponseDto>;
    updateRMProfile(profileId: number, dto: Partial<CreateRMProfileDto>, req: any): Promise<RMProfileResponseDto>;
    requestExport(dto: CreateExportJobDto, req: any): Promise<ExportJobResponseDto>;
    getExportJobStatus(jobId: string): Promise<ExportJobResponseDto>;
    downloadExportFile(jobId: string, req: any): Promise<any>;
    getColumnPreferences(req: any): Promise<any>;
    saveColumnPreferences(dto: any, req: any): Promise<{
        success: boolean;
    }>;
    getBranchStatistics(branchCode: string, startDate?: string, endDate?: string): Promise<BranchStatisticsDto>;
    getMultibranchReport(startDate?: string, endDate?: string): Promise<MultibranchReportDto>;
    createScheduledReport(dto: CreateScheduledReportDto, req: any): Promise<ScheduledReportResponseDto>;
    getScheduledReports(): Promise<ScheduledReportResponseDto[]>;
    updateScheduledReport(reportId: number, dto: Partial<CreateScheduledReportDto>, req: any): Promise<ScheduledReportResponseDto>;
    triggerReportGeneration(reportId: number, req: any): Promise<ReportRunDto>;
    getReportHistory(limit?: number): Promise<ReportRunDto[]>;
    createStudentRating(dto: CreateStudentRatingDto, req: any): Promise<StudentRatingResponseDto>;
    getStudentRatings(studentId: string): Promise<StudentRatingResponseDto[]>;
    getProductConfigs(bankId?: string): Promise<ProductConfigResponseDto[]>;
    createProductConfig(dto: CreateProductConfigDto, req: any): Promise<ProductConfigResponseDto>;
    updateProductConfig(configId: number, dto: Partial<CreateProductConfigDto>, req: any): Promise<ProductConfigResponseDto>;
    getChecklistConfigs(bankId?: string, productType?: string): Promise<ChecklistConfigResponseDto[]>;
    createChecklistConfig(dto: CreateChecklistConfigDto, req: any): Promise<ChecklistConfigResponseDto>;
    updateChecklistConfig(configId: number, dto: Partial<CreateChecklistConfigDto>, req: any): Promise<ChecklistConfigResponseDto>;
    getBranchConfigs(bankId?: string): Promise<BranchConfigResponseDto[]>;
    getBranchConfig(branchCode: string): Promise<BranchConfigResponseDto>;
    createBranchConfig(dto: CreateBranchConfigDto, req: any): Promise<BranchConfigResponseDto>;
    updateBranchConfig(configId: number, dto: Partial<CreateBranchConfigDto>, req: any): Promise<BranchConfigResponseDto>;
}
