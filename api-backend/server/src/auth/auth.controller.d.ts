import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { ReferralService } from '../referral/referral.service';
export declare class AuthController {
    private authService;
    private usersService;
    private referralService;
    constructor(authService: AuthService, usersService: UsersService, referralService: ReferralService);
    checkUserExists(email: string): Promise<{
        exists: boolean;
        message: string;
    }>;
    sendOtp(body: {
        email: string;
    }): Promise<{
        success: boolean;
        message: string;
        error: any;
    } | {
        success: boolean;
        message: string;
    }>;
    verifyOtp(body: {
        email: string;
        otp: string;
        referralCode?: string;
    }): Promise<{
        success: boolean;
        message: string;
        access_token: string;
        refresh_token: string;
        userId: any;
        userExists: boolean;
        hasUserDetails: boolean;
        firstName: any;
        lastName: any;
        phoneNumber: any;
        dateOfBirth: string;
        role: any;
    } | {
        success: boolean;
        message: string;
    }>;
    firebaseLogin(body: {
        idToken: string;
    }): Promise<{
        success: boolean;
        message: string;
        access_token: string;
        refresh_token: string;
        userId: any;
        userExists: boolean;
        hasUserDetails: boolean;
        firstName: any;
        lastName: any;
        phoneNumber: any;
        dateOfBirth: string;
        role: any;
        picture: string | undefined;
    } | {
        success: boolean;
        message: string;
    }>;
    refreshToken(body: {
        refresh_token: string;
    }): Promise<{
        success: boolean;
        message: string;
        access_token: string;
        refresh_token: string;
    } | {
        success: boolean;
        message: string;
    }>;
    logout(body: {
        email: string;
    }): Promise<{
        success: boolean;
        message: string;
    }>;
    getUserDashboard(body: {
        email: string;
    }): Promise<{
        success: boolean;
        user: {
            id: any;
            email: any;
            firstName: any;
            lastName: any;
            phoneNumber: any;
            dateOfBirth: string;
            role: any;
            profileImage: any;
            createdAt: any;
        };
        message?: undefined;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        error: any;
        user?: undefined;
    } | {
        success: boolean;
        message: string;
    }>;
    getDashboardData(body: {
        userId: string;
    }): Promise<{
        success: boolean;
        message: string;
        data?: undefined;
    } | {
        success: boolean;
        data: {
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
        };
        message?: undefined;
    }>;
    updateUserDetails(body: {
        email: string;
        firstName: string;
        lastName: string;
        phoneNumber: string;
        dateOfBirth: string;
        profileImage?: string;
    }): Promise<{
        success: boolean;
        message: string;
        user: {
            email: any;
            firstName: any;
            lastName: any;
            phoneNumber: any;
            dateOfBirth: any;
            profileImage: any;
        };
    } | {
        success: boolean;
        message: string;
    }>;
    createApplication(body: {
        userId: string;
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
    }): Promise<{
        success: boolean;
        message: string;
        application?: undefined;
    } | {
        success: boolean;
        application: any;
        message?: undefined;
    }>;
    getApplications(body: {
        userId: string;
    }): Promise<{
        success: boolean;
        message: string;
        applications?: undefined;
    } | {
        success: boolean;
        applications: any[];
        message?: undefined;
    }>;
    updateApplication(id: string, body: {
        status: string;
    }): Promise<{
        success: boolean;
        message: string;
        application?: undefined;
    } | {
        success: boolean;
        application: any;
        message?: undefined;
    }>;
    deleteApplication(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    uploadDocument(body: {
        userId: string;
        docType: string;
        uploaded: boolean;
        filePath?: string;
    }): Promise<{
        success: boolean;
        message: string;
        document?: undefined;
    } | {
        success: boolean;
        document: any;
        message?: undefined;
    }>;
    getDocuments(body: {
        userId: string;
    }): Promise<{
        success: boolean;
        message: string;
        documents?: undefined;
    } | {
        success: boolean;
        documents: any[];
        message?: undefined;
    }>;
    deleteDocument(userId: string, docType: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
