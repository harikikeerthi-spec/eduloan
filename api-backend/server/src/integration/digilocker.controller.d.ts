import { DigilockerService } from './digilocker.service';
import { UsersService } from '../users/users.service';
import { SupabaseService } from '../supabase/supabase.service';
import type { Response } from 'express';
export declare class DigilockerController {
    private readonly digilockerService;
    private readonly usersService;
    private readonly supabase;
    constructor(digilockerService: DigilockerService, usersService: UsersService, supabase: SupabaseService);
    private mockOtps;
    getStatus(): Promise<{
        mockMode: boolean;
        clientId: string;
        clientSecret: string;
        callbackUrl: string;
        message: string;
    }>;
    authorize(userId: string, docType: string, source: string, res: Response): Promise<void>;
    getMockLoginPage(state: string, res: any): void;
    mockSendOtp(body: {
        mobile: string;
    }): Promise<{
        success: boolean;
    }>;
    mockVerifyOtp(body: {
        mobile: string;
        otp: string;
    }): Promise<{
        success: boolean;
        user: {
            firstName: any;
            lastName: any;
        };
    } | {
        success: boolean;
        user?: undefined;
    }>;
    handleCallback(query: any, res: Response): Promise<void>;
    private normalizeDigilockerType;
    private processMockDocuments;
    private fetchAndStoreDocuments;
    syncDocument(body: {
        userId: string;
        docType: string;
    }): Promise<{
        success: boolean;
        message: string;
    }>;
}
