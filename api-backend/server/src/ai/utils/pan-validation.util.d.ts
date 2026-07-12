export declare const PAN_NUMBER_REGEX: RegExp;
export interface PanDocumentValidation {
    income_tax_department_heading_present: boolean;
    govt_of_india_branding_present: boolean;
    pan_number_format_valid: boolean;
    photo_present: boolean;
    signature_present: boolean;
    qr_code_present: boolean;
    dob_field_present: boolean;
}
export declare function isValidPanNumber(pan: string | undefined | null): boolean;
export declare function buildPanDocumentValidation(parsed: Record<string, any> | null | undefined, extracted: Record<string, any>): PanDocumentValidation;
export declare function validatePanExtraction(extracted: Record<string, any>, parsed?: Record<string, any> | null): {
    is_valid: boolean;
    error?: string;
    document_validation?: PanDocumentValidation;
};
