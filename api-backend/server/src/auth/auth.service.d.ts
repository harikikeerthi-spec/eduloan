import { UsersService } from '../users/users.service';
import { FirebaseAuthService } from './firebase-auth.service';
import { EmailService } from './email.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { EventEmitter2 } from '@nestjs/event-emitter';
export declare class AuthService {
    private usersService;
    private emailService;
    private jwtService;
    private configService;
    private eventEmitter;
    private firebaseAuthService;
    private otps;
    private signupData;
    constructor(usersService: UsersService, emailService: EmailService, jwtService: JwtService, configService: ConfigService, eventEmitter: EventEmitter2, firebaseAuthService: FirebaseAuthService);
    private generateTokens;
    sendOtp(email: string, isSignup?: boolean, signupInfo?: {
        firstName?: string;
        lastName?: string;
        phoneNumber?: string;
        dateOfBirth?: string;
    }): Promise<{
        success: boolean;
        message: string;
        redirect: string;
    } | {
        otp?: string | undefined;
        success: boolean;
        message: string;
        redirect?: undefined;
    }>;
    checkUserExists(email: string): Promise<{
        exists: boolean;
        message: string;
    }>;
    sendOtpUnified(email: string): Promise<{
        success: boolean;
        message: string;
        error?: undefined;
    } | {
        otp?: string | undefined;
        success: boolean;
        message: string;
        userExists: boolean;
        error?: undefined;
    } | {
        success: boolean;
        message: string;
        error: any;
    }>;
    verifyOtpUnified(email: string, otp: string): Promise<{
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
        access_token?: undefined;
        refresh_token?: undefined;
        userId?: undefined;
        userExists?: undefined;
        hasUserDetails?: undefined;
        firstName?: undefined;
        lastName?: undefined;
        phoneNumber?: undefined;
        dateOfBirth?: undefined;
        role?: undefined;
    }>;
    authenticateFirebaseUser(idToken: string): Promise<{
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
    }>;
    refreshTokens(refreshToken: string): Promise<{
        success: boolean;
        message: string;
        access_token: string;
        refresh_token: string;
    }>;
    logout(email: string): Promise<{
        success: boolean;
        message: string;
    }>;
    getUserDashboard(email: string): Promise<{
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
    }>;
    updateUserDetails(email: string, firstName: string, lastName: string, phoneNumber: string, dateOfBirth: string, profileImage?: string): Promise<{
        success: boolean;
        message: string;
        user?: undefined;
    } | {
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
    }>;
}
