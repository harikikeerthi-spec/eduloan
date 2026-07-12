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
export interface KycExtractionResult {
    document_type: 'aadhaar' | 'pan' | 'passport' | 'unknown';
    confidence_score: number;
    is_valid: boolean;
    fraud_detected?: boolean;
    fraud_reason?: string;
    extracted_data: any;
    document_validation?: AadhaarDocumentValidation | PanDocumentValidation | AcademicDocumentValidation;
    missing_fields?: string[];
    ocr_issues?: string[];
    raw_text_summary?: string;
    error?: string;
}
export declare class KycService {
    private readonly openRouterService;
    constructor(openRouterService: OpenRouterService);
    preprocessImage(buffer: Buffer): Promise<Buffer>;
    detectDocumentType(buffer: Buffer, mimetype: string): Promise<string>;
    processDocument(buffer: Buffer, mimetype: string, expectedType?: string): Promise<KycExtractionResult>;
    validateDocumentKeywords(buffer: Buffer, docType: string, isPdf: boolean, isImage: boolean): Promise<{
        is_valid: boolean;
        error?: string;
    }>;
    private logAudit;
    private getPromptForType;
    private parseAiResponse;
    private normalizeDocTypeForComparison;
    private validateAadhaarDocument;
    fallbackOcr(buffer: Buffer): Promise<string>;
    private extractDynamicFieldsFromText;
}
