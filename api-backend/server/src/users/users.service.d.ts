import { SupabaseService } from '../supabase/supabase.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
export declare class UsersService {
    private supabase;
    private eventEmitter;
    private get db();
    constructor(supabase: SupabaseService, eventEmitter: EventEmitter2);
    private parseDate;
    private safeISO;
    private convertToIndiaTime;
    findOne(email: string): Promise<any>;
    findById(id: string): Promise<any>;
    findByMobile(mobile: string): Promise<any>;
    private generateSequentialStudentId;
    private generateSequentialStaffId;
    private emailToNum;
    private generateNonStudentUserId;
    private createUniqueUserId;
    create(data: {
        email: string;
        firstName?: string;
        lastName?: string;
        phoneNumber?: string;
        dateOfBirth?: string;
        mobile?: string;
        password?: string;
        role?: string;
    }): Promise<any>;
    findAll(limit?: number, offset?: number, search?: string, role?: string): Promise<{
        data: any[];
        total: number;
    }>;
    getUserStats(): Promise<{
        total: number;
        student: number;
        bank: number;
        staff: number;
        other: number;
    }>;
    updateUserDetails(email: string, firstName: string, lastName: string, phoneNumber: string, dateOfBirth: string, profileImage?: string): Promise<any>;
    updateExtractedDetails(userId: string, details: any, docType?: string): Promise<{
        success: boolean;
        warning?: undefined;
        data?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        warning: string;
        data?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        data: any;
        warning?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        error: any;
        warning?: undefined;
        data?: undefined;
    }>;
    updateRefreshToken(email: string, refreshToken: string | null): Promise<any>;
    updateUserRole(email: string, role: 'admin' | 'user' | 'staff' | 'super_admin' | 'agent' | 'bank' | 'student'): Promise<any>;
    private validateApplicationConstraints;
    private generateApplicationNumber;
    createLoanApplication(userId: string, data: {
        bank: string;
        loanType: string;
        amount: number;
        purpose?: string;
        courseType?: string;
        courseName?: string;
        program?: string;
        programFocus?: string;
        country?: string;
        university?: string;
        universityName?: string;
        targetUniversity?: string;
        annualFee?: string;
        livingCost?: string;
        coApplicant?: string;
        income?: string;
        collateral?: string;
        firstName?: string;
        lastName?: string;
        email?: string;
        phone?: string;
        dateOfBirth?: string;
        address?: string;
        notes?: string;
    }): Promise<any>;
    getUserApplications(userId: string): Promise<any[]>;
    updateLoanApplicationStatus(applicationId: string, status: string): Promise<any>;
    deleteLoanApplication(applicationId: string): Promise<{
        success: boolean;
    }>;
    upsertUserDocument(userId: string, docType: string, data: {
        uploaded: boolean;
        status?: string;
        filePath?: string;
        digilockerTxId?: string;
        verifiedAt?: Date;
        verificationMetadata?: any;
    }): Promise<any>;
    getUserDocuments(userId: string): Promise<any[]>;
    deleteUserDocument(userId: string, docType: string): Promise<{
        success: boolean;
    }>;
    updateDocumentStatus(docId: string, status: string, rejectionReason?: string): Promise<any>;
    getUserDashboardData(userId: string): Promise<{
        applications: any[];
        documents: any[];
        activity: {
            type: string;
            title: string;
            description: string;
            timestamp: string;
            link?: string;
        }[];
        applicationCount: number;
        user: any;
    }>;
    deleteUser(userId: string): Promise<{
        success: boolean;
    }>;
    updateUserStatus(userId: string, status: string, rejectionReason?: string): Promise<any>;
}
