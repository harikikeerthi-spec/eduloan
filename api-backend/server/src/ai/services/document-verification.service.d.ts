import { PanDocumentValidation } from '../utils/pan-validation.util';
import { OpenRouterService } from './openrouter.service';
export interface AadhaarStructuredAddress {
    house_details?: string;
    area?: string;
    landmark?: string;
    mandal?: string;
    city?: string;
    district?: string;
    state?: string;
    pincode?: string;
}
export interface AadhaarDocumentValidation {
    aadhaar_logo_present: boolean;
    govt_of_india_branding_present: boolean;
    uidai_text_present: boolean;
    aadhaar_number_format_valid: boolean;
    vid_present: boolean;
    photo_present: boolean;
    dob_and_gender_fields_present: boolean;
}
export interface AcademicDocumentValidation {
    official_board_formatting_present?: boolean;
    seal_or_signature_area_present?: boolean;
    barcode_present?: boolean;
    certificate_number_present?: boolean;
    ssc_grade_format_consistent?: boolean;
    subject_table_present?: boolean;
}
export interface OcrVerificationResult {
    isValid: boolean;
    confidence: number;
    docType: string;
    extractedFields: {
        full_name?: string;
        date_of_birth?: string;
        document_number?: string;
        address?: string | AadhaarStructuredAddress;
        address_formatted?: string;
        father_name?: string;
        expiry_date?: string;
        issuing_authority?: string;
        gender?: string;
        vid?: string;
        panNumber?: string;
        aadhaarNumber?: string;
        passportNumber?: string;
        universityName?: string;
        programName?: string;
        studentId?: string;
        admissionYear?: string;
        [key: string]: string | AadhaarStructuredAddress | undefined;
    };
    document_validation?: AadhaarDocumentValidation | PanDocumentValidation | AcademicDocumentValidation;
    ocr_issues?: string[];
    verification_flags?: {
        is_expired: boolean;
        name_match_score: number;
    };
    matchResults?: {
        nameMatch?: boolean;
        dobMatch?: boolean;
        overallMatch: boolean;
        mismatches: string[];
    };
    reason?: string;
    rawOcrText?: string;
}
export declare class DocumentVerificationService {
    private readonly openRouterService;
    constructor(openRouterService: OpenRouterService);
    verifyAndExtractDocument(docType: string, fileBuffer: Buffer, mimetype: string, studentProfile?: any): Promise<OcrVerificationResult>;
    reverifyDocumentForAdmin(fileBuffer: Buffer, mimetype: string, docType: string, studentProfile: {
        firstName: string;
        lastName: string;
        dateOfBirth?: string;
        email?: string;
    }): Promise<OcrVerificationResult>;
    private normalizeAadhaarExtractedFields;
    private validateAadhaarExtraction;
    private namesMatch;
    private fallbackVerification;
    explainRejection(docType: string, reason: string): Promise<string>;
}
