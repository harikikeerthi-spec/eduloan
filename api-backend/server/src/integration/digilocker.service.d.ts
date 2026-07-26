export interface VerificationResult {
    isValid: boolean;
    txId?: string;
    code?: string;
    details?: any;
}
export declare class DigilockerService {
    private readonly baseUrl;
    private readonly authUrl;
    private readonly tokenUrl;
    private readonly issuedDocsUrl;
    private readonly clientId;
    private readonly clientSecret;
    getAuthUrl(state: string, redirectUri: string, codeChallenge: string): string;
    getAccessToken(code: string, redirectUri: string, codeVerifier?: string): Promise<any>;
    listDocuments(token: string): Promise<any[]>;
    downloadDocument(token: string, uri: string): Promise<Buffer>;
    verifyDocument(token: string, docType: string): Promise<VerificationResult>;
}
