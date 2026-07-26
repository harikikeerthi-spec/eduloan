import { UsersService } from '../users/users.service';
import { DigilockerService } from '../integration/digilocker.service';
import { DocumentVerificationService } from '../ai/services/document-verification.service';
import { KycService } from '../ai/services/kyc.service';
import { S3Service } from './s3.service';
import { SupabaseService } from '../supabase/supabase.service';
import type { Response } from 'express';
export declare class DocumentController {
    private usersService;
    private digilockerService;
    private docVerificationService;
    private kycService;
    private s3Service;
    private supabase;
    constructor(usersService: UsersService, digilockerService: DigilockerService, docVerificationService: DocumentVerificationService, kycService: KycService, s3Service: S3Service, supabase: SupabaseService);
    uploadFile(file: Express.Multer.File, userId: string, docType: string): Promise<{
        success: boolean;
        message: string;
        data: any;
        file: {
            originalName: string;
            s3Key: string;
        };
    }>;
    ocrReverify(userId: string, docType: string): Promise<{
        success: boolean;
        data: {
            docType: string;
            userId: string;
            isValid: any;
            confidence: any;
            extractedFields: any;
            reason: any;
            newStatus: string;
            verification: {
                isValid: any;
                code: string;
                confidence: any;
                details: {
                    message: any;
                    extractedFields: any;
                    document_validation: any;
                    ocr_issues: any;
                };
            };
            ocrResult: {
                isValid: any;
                confidence: any;
                extractedFields: any;
                document_validation: any;
                ocr_issues: any;
            };
        };
    }>;
    initiateDigilockerFlow(userId: string, docType: string, redirectUri: string): Promise<{
        success: boolean;
        authUrl: string;
    }>;
    viewDocument(userId: string, docType: string, bankId: string, res: Response): Promise<void | Response<any, Record<string, any>>>;
    getPresignedViewUrl(userId: string, docType: string, bankId: string): Promise<{
        success: boolean;
        url: string;
        docType: string;
        filePath: any;
    }>;
    getUserDocuments(userId: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    deleteDocument(userId: string, docType: string): Promise<{
        success: boolean;
        message: string;
    }>;
    addRequirement(userId: string, docType: string, docName?: string): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    acceptDocument(docId: string): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    rejectDocument(docId: string, rejectionReason?: string): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    sendDocumentToBank(userId: string, docType: string, docTitle: string, bankId: string, bankName: string, notes?: string, studentName?: string, applicationNumber?: string): Promise<{
        success: boolean;
        message: string;
        data: {
            transmissionId: string;
            bankId: string;
            bankName: string;
            docType: string;
            studentName: string | undefined;
            applicationNumber: string | undefined;
            presignedUrl: string;
            expiresAt: string;
        };
    }>;
}
