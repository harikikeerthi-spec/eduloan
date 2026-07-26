export declare class CreateBankSchemeDto {
    name: string;
    bank: string;
    description?: string;
    minAmount?: number;
    maxAmount?: number;
    interestRateMin?: number;
    interestRateMax?: number;
    repaymentYearsMin?: number;
    repaymentYearsMax?: number;
    eligibility?: Record<string, any>;
    documentsRequired?: string[];
    processingFee?: number;
    validityStart?: Date;
    validityEnd?: Date;
    visibleTo?: 'all' | 'staff' | 'partners';
}
export declare class BankSchemeResponseDto extends CreateBankSchemeDto {
    id: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    createdBy?: string;
    daysUntilExpiry?: number;
}
export declare class CreateAssignmentRuleDto {
    name: string;
    priority?: number;
    ruleType: 'region' | 'amount' | 'course' | 'roundrobin';
    conditions: Record<string, any>;
    assignTo: 'officer' | 'senior_officer' | 'specialist' | 'next_available';
    assignToValue?: string;
    isActive?: boolean;
}
export declare class AssignmentRuleResponseDto extends CreateAssignmentRuleDto {
    id: number;
    createdAt: Date;
    updatedAt: Date;
}
export declare class AssignmentLogDto {
    id: number;
    applicationId: string;
    ruleId: number;
    assignedTo: string;
    reason?: string;
    createdAt: Date;
}
export declare class CreateOfficerTargetDto {
    officerId: string;
    targetMonth: Date;
    targetApplications: number;
    targetAmount: number;
    targetConversions?: number;
    notes?: string;
}
export declare class OfficerTargetResponseDto extends CreateOfficerTargetDto {
    id: number;
    createdAt: Date;
    updatedAt: Date;
    achievements?: {
        applicationsProcessed: number;
        amountProcessed: number;
        conversions: number;
        progressPercentage: number;
    };
}
export declare class CreateRMProfileDto {
    userId: string;
    region?: string;
    businessVertical?: string;
    portfolio?: Record<string, any>;
    commissionStructure?: Record<string, any>;
}
export declare class RMProfileResponseDto extends CreateRMProfileDto {
    id: number;
    createdAt: Date;
    updatedAt: Date;
}
export declare class CreateExportJobDto {
    jobType: 'applications' | 'users' | 'schemes' | 'reports';
    filters?: Record<string, any>;
    format?: 'csv' | 'excel' | 'pdf';
    columns?: string[];
}
export declare class ExportJobResponseDto {
    id: string;
    userId: string;
    jobType: string;
    status: 'pending' | 'processing' | 'completed' | 'failed';
    fileUrl?: string;
    fileSize?: number;
    totalRecords: number;
    processedRecords: number;
    errorMessage?: string;
    requestedAt: Date;
    completedAt?: Date;
    expiresAt?: Date;
}
export declare class ColumnConfigDto {
    jobType: string;
    selectedColumns: string[];
    isDefault?: boolean;
}
export declare class CreateScheduledReportDto {
    name: string;
    reportType: 'daily_summary' | 'weekly_pipeline' | 'monthly_mis';
    frequency: 'daily' | 'weekly' | 'monthly';
    scheduleTime: string;
    scheduleDay?: string;
    recipients: string[];
    isActive?: boolean;
}
export declare class ScheduledReportResponseDto extends CreateScheduledReportDto {
    id: number;
    lastRunAt?: Date;
    nextRunAt?: Date;
    createdAt: Date;
}
export declare class ReportRunDto {
    id: number;
    reportId: number;
    status: 'success' | 'failed';
    fileUrl?: string;
    recordsIncluded: number;
    executedAt: Date;
}
export declare class CreateStudentRatingDto {
    studentId: string;
    applicationId?: string;
    rating: number;
    feedback?: string;
    category?: 'cooperation' | 'documentation' | 'communication';
}
export declare class StudentRatingResponseDto extends CreateStudentRatingDto {
    id: number;
    ratedBy: string;
    createdAt: Date;
}
export declare class StudentRatingAggregateDto {
    studentId: string;
    avgRating: number;
    totalRatings: number;
    lastUpdated: Date;
}
export declare class CreateProductConfigDto {
    bankId: string;
    productType: string;
    productName: string;
    description?: string;
    features?: Record<string, any>;
    parameters?: Record<string, any>;
    isActive?: boolean;
}
export declare class ProductConfigResponseDto extends CreateProductConfigDto {
    id: number;
    createdAt: Date;
    updatedAt: Date;
    createdBy?: string;
}
export declare class CreateChecklistConfigDto {
    bankId: string;
    productType?: string;
    checklistName: string;
    items: Array<{
        name: string;
        required: boolean;
        conditional: boolean;
    }>;
    displayOrder?: number;
    isActive?: boolean;
}
export declare class ChecklistConfigResponseDto extends CreateChecklistConfigDto {
    id: number;
    createdAt: Date;
    updatedAt: Date;
}
export declare class CreateBranchConfigDto {
    branchCode: string;
    branchName: string;
    bankId?: string;
    location?: string;
    region?: string;
    staffCount?: number;
    maxDailyApplications?: number;
    processingCapacity?: number;
    configuration?: Record<string, any>;
    isActive?: boolean;
}
export declare class BranchConfigResponseDto extends CreateBranchConfigDto {
    id: number;
    createdAt: Date;
    updatedAt: Date;
    createdBy?: string;
}
export declare class BranchStatisticsDto {
    branchCode: string;
    branchName: string;
    applicationsProcessed: number;
    totalAmountProcessed: number;
    conversions: number;
    averageProcessingTime: number;
    staffUtilization: number;
}
export declare class MultibranchReportDto {
    reportDate: Date;
    branches: BranchStatisticsDto[];
    totalStatistics: {
        totalApplications: number;
        totalAmount: number;
        totalConversions: number;
        averageConversionRate: number;
    };
}
