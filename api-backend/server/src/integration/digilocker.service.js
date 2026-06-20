"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DigilockerService = void 0;
const common_1 = require("@nestjs/common");
let DigilockerService = class DigilockerService {
    baseUrl = 'https://api.digitallocker.gov.in';
    authUrl = 'https://api.digitallocker.gov.in/public/oauth2/1/authorize';
    tokenUrl = 'https://api.digitallocker.gov.in/public/oauth2/1/token';
    issuedDocsUrl = 'https://api.digitallocker.gov.in/public/oauth2/2/files/issued';
    clientId = process.env.DIGILOCKER_CLIENT_ID;
    clientSecret = process.env.DIGILOCKER_CLIENT_SECRET;
    getAuthUrl(state, redirectUri, codeChallenge) {
        const params = new URLSearchParams({
            response_type: 'code',
            client_id: this.clientId || '',
            redirect_uri: redirectUri,
            state: state,
            code_challenge: codeChallenge,
            code_challenge_method: 'S256',
        });
        return `${this.authUrl}?${params.toString()}`;
    }
    async getAccessToken(code, redirectUri, codeVerifier) {
        console.log('DIGILOCKER_DEBUG: Exchanging code for token...');
        const bodyParams = {
            grant_type: 'authorization_code',
            code: code,
            client_id: this.clientId || '',
            client_secret: this.clientSecret || '',
            redirect_uri: redirectUri,
        };
        if (codeVerifier) {
            bodyParams.code_verifier = codeVerifier;
        }
        const body = new URLSearchParams(bodyParams).toString();
        console.log('DIGILOCKER_DEBUG: Token Request to:', this.tokenUrl);
        console.log('DIGILOCKER_DEBUG: redirect_uri used:', redirectUri);
        const response = await fetch(this.tokenUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
        });
        if (!response.ok) {
            const err = await response.text();
            console.error('DIGILOCKER_DEBUG: Token exchange failed:', err);
            throw new Error(`DigiLocker Token Error: ${err}`);
        }
        const data = await response.json();
        console.log('DIGILOCKER_DEBUG: Token exchange success. access_token present:', !!data.access_token);
        return data;
    }
    async listDocuments(token) {
        console.log('DIGILOCKER_DEBUG: Fetching issued documents from:', this.issuedDocsUrl);
        const response = await fetch(this.issuedDocsUrl, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Accept': 'application/json',
            }
        });
        if (!response.ok) {
            const err = await response.text();
            console.error('DIGILOCKER_DEBUG: Failed to fetch documents:', err);
            throw new Error(`DigiLocker Documents Error: ${err}`);
        }
        const data = await response.json();
        console.log('DIGILOCKER_DEBUG: Raw documents response:', JSON.stringify(data, null, 2));
        const extractArray = (resp) => {
            if (Array.isArray(resp))
                return resp;
            if (Array.isArray(resp?.items))
                return resp.items;
            if (Array.isArray(resp?.documents))
                return resp.documents;
            if (Array.isArray(resp?.issued_documents))
                return resp.issued_documents;
            if (Array.isArray(resp?.issuedDocuments))
                return resp.issuedDocuments;
            if (Array.isArray(resp?.result?.items))
                return resp.result.items;
            return [];
        };
        const allDocs = extractArray(data);
        console.log(`DIGILOCKER_DEBUG: Total issued documents: ${allDocs.length}`);
        allDocs.forEach((d, i) => {
            console.log(`  [${i}] doctype="${d.doctype || d.type}" name="${d.name}" uri="${d.uri}"`);
        });
        return allDocs;
    }
    async downloadDocument(token, uri) {
        const url = `${this.baseUrl}/public/oauth2/1/file/${encodeURIComponent(uri)}`;
        const response = await fetch(url, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Accept': 'application/pdf',
            }
        });
        if (!response.ok) {
            const err = await response.text();
            throw new Error(`DigiLocker Download Error: ${err}`);
        }
        const arrayBuffer = await response.arrayBuffer();
        return Buffer.from(arrayBuffer);
    }
    async verifyDocument(token, docType) {
        try {
            const docs = await this.listDocuments(token);
            const typeMap = {
                'pan_student': 'PANCR',
                'pan_coapp': 'PANCR',
                'pan_father': 'PANCR',
                'pan_mother': 'PANCR',
                'aadhar_student': 'ADHAR',
                'aadhar_coapp': 'ADHAR',
                'aadhar_father': 'ADHAR',
                'aadhar_mother': 'ADHAR',
                'marksheet_10th': 'HSCER',
                'marksheet_12th': 'HSCER',
                'passport': 'PASPT',
                'marksheet_degree': 'DGCTR',
                'btech_degree': 'DGCTR',
                'graduation_marksheet': 'MKST',
            };
            const targetDlType = typeMap[docType] || docType.toUpperCase();
            const doc = docs.find((item) => (item.doctype || '').toUpperCase() === targetDlType ||
                (item.type || '').toUpperCase() === targetDlType);
            if (doc) {
                return {
                    isValid: true,
                    txId: doc.uri || 'DGL-' + Math.random().toString(36).substring(7),
                    code: 'VERIFIED_DIGILOCKER',
                    details: {
                        source: 'DigiLocker',
                        document_name: doc.name || doc.description,
                        issuer: doc.issuerid,
                        status: 'Issued',
                        verified_at: new Date().toISOString(),
                    }
                };
            }
            return {
                isValid: false,
                code: 'DOC_NOT_FOUND',
                details: { message: `Could not find ${docType} in your DigiLocker account.` }
            };
        }
        catch (error) {
            return {
                isValid: false,
                code: 'VERIFICATION_ERROR',
                details: { message: error.message }
            };
        }
    }
};
exports.DigilockerService = DigilockerService;
exports.DigilockerService = DigilockerService = __decorate([
    (0, common_1.Injectable)()
], DigilockerService);
//# sourceMappingURL=digilocker.service.js.map