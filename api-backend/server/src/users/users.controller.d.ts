import { UsersService } from './users.service';
import { EmailService } from '../auth/email.service';
export declare class UsersController {
    private readonly usersService;
    private readonly emailService;
    constructor(usersService: UsersService, emailService: EmailService);
    getProfile(body: {
        email: string;
    }): Promise<{
        success: boolean;
        message: string;
        user?: undefined;
    } | {
        success: boolean;
        user: {
            id: any;
            email: any;
            firstName: any;
            lastName: any;
            phoneNumber: any;
            dateOfBirth: string;
            mobile: any;
            role: any;
            registeredAtIndia: any;
            panNumber: any;
            aadhaarNumber: any;
            fatherName: any;
            permanentAddress: any;
            gender: any;
            documentVerified: any;
            status: any;
            rejectionReason: any;
            goal: any;
            studyDestination: any;
            courseName: any;
            targetUniversity: any;
            intakeSeason: any;
            bachelorsDegree: any;
            gpa: any;
            workExp: any;
            entranceTest: any;
            entranceScore: any;
            englishTest: any;
            englishScore: any;
            budget: any;
            pincode: any;
            loanAmount: any;
            admitStatus: any;
            passport: any;
            nationality: any;
            mailingAddress: any;
            emergencyContact: any;
            academic: any;
            workExperience: any;
            tests: any;
            family: any;
            coApplicant: any;
            createdAt: any;
        };
        message?: undefined;
    }>;
    getUserStats(): Promise<{
        total: number;
        student: number;
        bank: number;
        staff: number;
        other: number;
    }>;
    listUsers(limit?: string, offset?: string, search?: string, role?: string): Promise<{
        success: boolean;
        data: never[];
        total: number;
        limit?: undefined;
        offset?: undefined;
        message?: undefined;
    } | {
        success: boolean;
        data: {
            id: any;
            email: any;
            firstName: any;
            lastName: any;
            phoneNumber: any;
            mobile: any;
            role: any;
            createdAt: any;
            registeredAtIndia: any;
        }[];
        total: number;
        limit: number;
        offset: number;
        message?: undefined;
    } | {
        success: boolean;
        message: any;
        data: never[];
        total: number;
        limit?: undefined;
        offset?: undefined;
    }>;
    makeAdmin(body: {
        email: string;
        role: string;
    }): Promise<{
        success: boolean;
        message: string;
        user?: undefined;
    } | {
        success: boolean;
        message: string;
        user: {
            id: any;
            email: any;
            firstName: any;
            lastName: any;
            role: any;
        };
    }>;
    sendAdminEmail(body: {
        to: string;
        subject: string;
        content: string;
        role?: string;
        isBulk?: boolean;
    }): Promise<{
        success: boolean;
        message: string;
    }>;
    adminCreateUser(body: {
        email: string;
        firstName: string;
        lastName: string;
        mobile: string;
        role: string;
    }): Promise<{
        success: boolean;
        message: string;
        user: {
            id: any;
            email: any;
            firstName: any;
            lastName: any;
            role: any;
        };
    } | {
        success: boolean;
        message: string;
        error: any;
    } | {
        success: boolean;
        message: string;
    }>;
    adminUpdateUser(body: {
        email: string;
        firstName: string;
        lastName: string;
        phoneNumber: string;
        dateOfBirth: string;
    }): Promise<{
        success: boolean;
        message: string;
        user?: undefined;
    } | {
        success: boolean;
        message: string;
        user: any;
    }>;
    adminUpdateUserStatus(body: {
        userId: string;
        status: string;
        rejectionReason?: string;
    }): Promise<{
        success: boolean;
        message: string;
        user?: undefined;
    } | {
        success: boolean;
        message: string;
        user: {
            id: any;
            email: any;
            status: any;
            rejectionReason: any;
        };
    }>;
    getUserById(id: string): Promise<{
        success: boolean;
        message: string;
        data?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        data: {
            id: any;
            email: any;
            firstName: any;
            lastName: any;
            phoneNumber: any;
            dateOfBirth: string;
            mobile: any;
            role: any;
            registeredAtIndia: any;
            panNumber: any;
            aadhaarNumber: any;
            fatherName: any;
            permanentAddress: any;
            gender: any;
            documentVerified: any;
            status: any;
            rejectionReason: any;
            goal: any;
            studyDestination: any;
            courseName: any;
            targetUniversity: any;
            intakeSeason: any;
            bachelorsDegree: any;
            gpa: any;
            workExp: any;
            entranceTest: any;
            entranceScore: any;
            englishTest: any;
            englishScore: any;
            budget: any;
            pincode: any;
            loanAmount: any;
            admitStatus: any;
            passport: any;
            nationality: any;
            mailingAddress: any;
            emergencyContact: any;
            academic: any;
            workExperience: any;
            tests: any;
            family: any;
            coApplicant: any;
            createdAt: any;
        };
        message?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        error: any;
        data?: undefined;
    }>;
    deleteUser(id: string): Promise<{
        success: boolean;
        message: string;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        error: any;
    }>;
}
