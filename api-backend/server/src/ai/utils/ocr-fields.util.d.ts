export declare function dedupeOcrFullName(raw: string): string;
export declare function normalizeCountryName(country: string): string;
export declare function parsePlaceOfBirth(pob: string): {
    birth_city?: string;
    birth_country?: string;
};
export declare function extractNameFromLabeledOcrText(text: string): string | undefined;
export declare function parseMRZLine1(line: string, rawText?: string): {
    surname?: string;
    given_names?: string;
    full_name?: string;
};
export declare function parseMRZLine2(line: string): {
    passport_number?: string;
    dob?: string;
    gender?: string;
    date_of_expiry?: string;
};
export declare function extractFullNameFromOcrRaw(raw: Record<string, any>, docType?: string): string | undefined;
export declare function canonicalizeOcrFields(raw: Record<string, any>, docType: string): Record<string, any>;
export declare function maskSensitiveIds(data: Record<string, any>, docType: string): Record<string, any>;
