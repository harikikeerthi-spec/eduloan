"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultibranchReportDto = exports.BranchStatisticsDto = exports.BranchConfigResponseDto = exports.CreateBranchConfigDto = exports.ChecklistConfigResponseDto = exports.CreateChecklistConfigDto = exports.ProductConfigResponseDto = exports.CreateProductConfigDto = exports.StudentRatingAggregateDto = exports.StudentRatingResponseDto = exports.CreateStudentRatingDto = exports.ReportRunDto = exports.ScheduledReportResponseDto = exports.CreateScheduledReportDto = exports.ColumnConfigDto = exports.ExportJobResponseDto = exports.CreateExportJobDto = exports.RMProfileResponseDto = exports.CreateRMProfileDto = exports.OfficerTargetResponseDto = exports.CreateOfficerTargetDto = exports.AssignmentLogDto = exports.AssignmentRuleResponseDto = exports.CreateAssignmentRuleDto = exports.BankSchemeResponseDto = exports.CreateBankSchemeDto = void 0;
class CreateBankSchemeDto {
    name;
    bank;
    description;
    minAmount;
    maxAmount;
    interestRateMin;
    interestRateMax;
    repaymentYearsMin;
    repaymentYearsMax;
    eligibility;
    documentsRequired;
    processingFee;
    validityStart;
    validityEnd;
    visibleTo;
}
exports.CreateBankSchemeDto = CreateBankSchemeDto;
class BankSchemeResponseDto extends CreateBankSchemeDto {
    id;
    isActive;
    createdAt;
    updatedAt;
    createdBy;
    daysUntilExpiry;
}
exports.BankSchemeResponseDto = BankSchemeResponseDto;
class CreateAssignmentRuleDto {
    name;
    priority;
    ruleType;
    conditions;
    assignTo;
    assignToValue;
    isActive;
}
exports.CreateAssignmentRuleDto = CreateAssignmentRuleDto;
class AssignmentRuleResponseDto extends CreateAssignmentRuleDto {
    id;
    createdAt;
    updatedAt;
}
exports.AssignmentRuleResponseDto = AssignmentRuleResponseDto;
class AssignmentLogDto {
    id;
    applicationId;
    ruleId;
    assignedTo;
    reason;
    createdAt;
}
exports.AssignmentLogDto = AssignmentLogDto;
class CreateOfficerTargetDto {
    officerId;
    targetMonth;
    targetApplications;
    targetAmount;
    targetConversions;
    notes;
}
exports.CreateOfficerTargetDto = CreateOfficerTargetDto;
class OfficerTargetResponseDto extends CreateOfficerTargetDto {
    id;
    createdAt;
    updatedAt;
    achievements;
}
exports.OfficerTargetResponseDto = OfficerTargetResponseDto;
class CreateRMProfileDto {
    userId;
    region;
    businessVertical;
    portfolio;
    commissionStructure;
}
exports.CreateRMProfileDto = CreateRMProfileDto;
class RMProfileResponseDto extends CreateRMProfileDto {
    id;
    createdAt;
    updatedAt;
}
exports.RMProfileResponseDto = RMProfileResponseDto;
class CreateExportJobDto {
    jobType;
    filters;
    format;
    columns;
}
exports.CreateExportJobDto = CreateExportJobDto;
class ExportJobResponseDto {
    id;
    userId;
    jobType;
    status;
    fileUrl;
    fileSize;
    totalRecords;
    processedRecords;
    errorMessage;
    requestedAt;
    completedAt;
    expiresAt;
}
exports.ExportJobResponseDto = ExportJobResponseDto;
class ColumnConfigDto {
    jobType;
    selectedColumns;
    isDefault;
}
exports.ColumnConfigDto = ColumnConfigDto;
class CreateScheduledReportDto {
    name;
    reportType;
    frequency;
    scheduleTime;
    scheduleDay;
    recipients;
    isActive;
}
exports.CreateScheduledReportDto = CreateScheduledReportDto;
class ScheduledReportResponseDto extends CreateScheduledReportDto {
    id;
    lastRunAt;
    nextRunAt;
    createdAt;
}
exports.ScheduledReportResponseDto = ScheduledReportResponseDto;
class ReportRunDto {
    id;
    reportId;
    status;
    fileUrl;
    recordsIncluded;
    executedAt;
}
exports.ReportRunDto = ReportRunDto;
class CreateStudentRatingDto {
    studentId;
    applicationId;
    rating;
    feedback;
    category;
}
exports.CreateStudentRatingDto = CreateStudentRatingDto;
class StudentRatingResponseDto extends CreateStudentRatingDto {
    id;
    ratedBy;
    createdAt;
}
exports.StudentRatingResponseDto = StudentRatingResponseDto;
class StudentRatingAggregateDto {
    studentId;
    avgRating;
    totalRatings;
    lastUpdated;
}
exports.StudentRatingAggregateDto = StudentRatingAggregateDto;
class CreateProductConfigDto {
    bankId;
    productType;
    productName;
    description;
    features;
    parameters;
    isActive;
}
exports.CreateProductConfigDto = CreateProductConfigDto;
class ProductConfigResponseDto extends CreateProductConfigDto {
    id;
    createdAt;
    updatedAt;
    createdBy;
}
exports.ProductConfigResponseDto = ProductConfigResponseDto;
class CreateChecklistConfigDto {
    bankId;
    productType;
    checklistName;
    items;
    displayOrder;
    isActive;
}
exports.CreateChecklistConfigDto = CreateChecklistConfigDto;
class ChecklistConfigResponseDto extends CreateChecklistConfigDto {
    id;
    createdAt;
    updatedAt;
}
exports.ChecklistConfigResponseDto = ChecklistConfigResponseDto;
class CreateBranchConfigDto {
    branchCode;
    branchName;
    bankId;
    location;
    region;
    staffCount;
    maxDailyApplications;
    processingCapacity;
    configuration;
    isActive;
}
exports.CreateBranchConfigDto = CreateBranchConfigDto;
class BranchConfigResponseDto extends CreateBranchConfigDto {
    id;
    createdAt;
    updatedAt;
    createdBy;
}
exports.BranchConfigResponseDto = BranchConfigResponseDto;
class BranchStatisticsDto {
    branchCode;
    branchName;
    applicationsProcessed;
    totalAmountProcessed;
    conversions;
    averageProcessingTime;
    staffUtilization;
}
exports.BranchStatisticsDto = BranchStatisticsDto;
class MultibranchReportDto {
    reportDate;
    branches;
    totalStatistics;
}
exports.MultibranchReportDto = MultibranchReportDto;
//# sourceMappingURL=bank-features.dto.js.map