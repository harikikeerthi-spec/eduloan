"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DocumentController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const users_service_1 = require("../users/users.service");
const digilocker_service_1 = require("../integration/digilocker.service");
const document_verification_service_1 = require("../ai/services/document-verification.service");
const kyc_service_1 = require("../ai/services/kyc.service");
const ocr_fields_util_1 = require("../ai/utils/ocr-fields.util");
const s3_service_1 = require("./s3.service");
const supabase_service_1 = require("../supabase/supabase.service");
const multer_1 = require("multer");
const crypto = __importStar(require("crypto"));
const storage = (0, multer_1.memoryStorage)();
let DocumentController = class DocumentController {
    usersService;
    digilockerService;
    docVerificationService;
    kycService;
    s3Service;
    supabase;
    constructor(usersService, digilockerService, docVerificationService, kycService, s3Service, supabase) {
        this.usersService = usersService;
        this.digilockerService = digilockerService;
        this.docVerificationService = docVerificationService;
        this.kycService = kycService;
        this.s3Service = s3Service;
        this.supabase = supabase;
    }
    async uploadFile(file, userId, docType) {
        if (!file)
            throw new common_1.BadRequestException('File is required');
        if (!userId || !docType)
            throw new common_1.BadRequestException('userId and docType are required');
        console.log(`[UPLOAD] Processing pre-storage check: userId=${userId}, docType=${docType}, file=${file.originalname} (${file.size} bytes)`);
        try {
            console.log(`[UPLOAD] Running pre-storage KYC verification for ${docType}...`);
            let kycResult;
            try {
                kycResult = await this.kycService.processDocument(file.buffer, file.mimetype, docType);
            }
            catch (aiError) {
                console.error(`[UPLOAD] KYC Service threw an error: ${aiError.message || aiError}. Running local keyword check...`);
                const isImage = file.mimetype.startsWith('image/');
                const isPdf = file.mimetype === 'application/pdf';
                const integrityCheck = await this.kycService.validateDocumentKeywords(file.buffer, docType, isPdf, isImage);
                if (!integrityCheck.is_valid) {
                    console.warn(`[UPLOAD] Rejecting invalid ${docType} on KYC service exception. Error: ${integrityCheck.error}`);
                    throw new common_1.BadRequestException(`Document verification failed: The uploaded file was not recognized as a valid ${docType.toUpperCase().replace(/_/g, ' ')}. ` +
                        `Details: ${integrityCheck.error}. Please check your document and re-upload the correct file.`);
                }
                kycResult = {
                    document_type: docType,
                    confidence_score: 50,
                    is_valid: true,
                    extracted_data: {},
                    error: `AI verification service temporarily offline: ${aiError.message || 'Unknown error'}`
                };
            }
            console.log(`[UPLOAD] KYC pre-check result: valid=${kycResult.is_valid}, confidence=${kycResult.confidence_score}%`);
            if (!kycResult.is_valid) {
                const docLabel = docType.toUpperCase().replace(/_/g, ' ');
                const errorMessage = kycResult.error || 'The uploaded file does not match the expected document type or has validation errors.';
                console.warn(`[UPLOAD] Rejecting invalid ${docType}. OCR Error: ${errorMessage}`);
                throw new common_1.BadRequestException(`Document verification failed: The uploaded file was not recognized as a valid ${docLabel}. ` +
                    `Details: ${errorMessage}. Please check your document and re-upload the correct file.`);
            }
            const s3Key = this.s3Service.buildKey(userId, docType, file.originalname);
            let previewUrl = '';
            try {
                await this.s3Service.upload(s3Key, file.buffer, file.mimetype);
                console.log(`[UPLOAD] Verified document stored in S3: ${s3Key}`);
                previewUrl = await this.s3Service.getPresignedUrl(s3Key, 3600);
            }
            catch (s3Error) {
                console.warn(`[UPLOAD] AWS S3 Upload failed: ${s3Error.message || s3Error}. Falling back to local storage routing.`);
                try {
                    const fs = require('fs');
                    const path = require('path');
                    const localDir = path.join(process.cwd(), 'uploads', userId, docType);
                    fs.mkdirSync(localDir, { recursive: true });
                    fs.writeFileSync(path.join(localDir, file.originalname), file.buffer);
                    console.log(`[UPLOAD] Graceful local fallback copy saved at: ${localDir}`);
                }
                catch (localWriteError) {
                    console.error('[UPLOAD] Local write fallback failed:', localWriteError.message);
                }
                previewUrl = `/api/documents/view/${userId}/${docType}`;
            }
            const verificationResult = {
                isValid: true,
                code: 'AI_VERIFIED',
                confidence: kycResult.confidence_score,
                details: {
                    message: 'Document verified by AI OCR pre-storage.',
                    extractedFields: kycResult.extracted_data,
                    document_validation: kycResult.document_validation,
                    ocr_issues: kycResult.ocr_issues,
                },
            };
            if (kycResult.extracted_data &&
                Object.keys(kycResult.extracted_data).length > 0) {
                await this.usersService.updateExtractedDetails(userId, {
                    documentVerified: true,
                    ...(0, ocr_fields_util_1.maskSensitiveIds)(kycResult.extracted_data, docType),
                }, docType);
            }
            const document = await this.usersService.upsertUserDocument(userId, docType, {
                uploaded: true,
                filePath: s3Key,
                status: 'uploaded',
                verificationMetadata: verificationResult,
            });
            console.log(`[UPLOAD] DB record saved. Doc ID: ${document?.id}`);
            return {
                success: true,
                message: 'Document validated, stored in S3, and registered successfully',
                data: {
                    ...document,
                    status: 'uploaded',
                    previewUrl,
                    verification: verificationResult,
                    aiExplanation: null,
                    ocrResult: {
                        isValid: true,
                        confidence: kycResult.confidence_score,
                        extractedFields: kycResult.extracted_data,
                        document_validation: kycResult.document_validation,
                        ocr_issues: kycResult.ocr_issues,
                        reason: 'Verified',
                    },
                },
                file: {
                    originalName: file.originalname,
                    s3Key,
                },
            };
        }
        catch (error) {
            console.error('[UPLOAD] Error:', error?.message);
            if (error instanceof common_1.BadRequestException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Upload failed: ${error.message || 'Processing error'}`);
        }
    }
    async ocrReverify(userId, docType) {
        if (!userId || !docType)
            throw new common_1.BadRequestException('userId and docType are required');
        console.log(`[OCR-REVERIFY] userId=${userId}, docType=${docType}`);
        const docs = await this.usersService.getUserDocuments(userId);
        const doc = docs.find((d) => d.docType === docType);
        if (!doc || !doc.filePath) {
            throw new common_1.NotFoundException('Document not found. Please upload the document first.');
        }
        const presignedUrl = await this.s3Service.getPresignedUrl(doc.filePath);
        const res = await fetch(presignedUrl);
        if (!res.ok)
            throw new common_1.NotFoundException('Could not retrieve document from S3.');
        const fileBuffer = Buffer.from(await res.arrayBuffer());
        const mimetype = doc.filePath.endsWith('.pdf')
            ? 'application/pdf'
            : 'image/jpeg';
        let kycResult;
        try {
            kycResult = await this.kycService.processDocument(fileBuffer, mimetype, docType);
        }
        catch (aiError) {
            console.error(`[OCR-REVERIFY] KYC Service threw an error: ${aiError.message || aiError}. Running local keyword check fallback...`);
            const isImage = mimetype.startsWith('image/');
            const isPdf = mimetype === 'application/pdf';
            const integrityCheck = await this.kycService.validateDocumentKeywords(fileBuffer, docType, isPdf, isImage);
            if (!integrityCheck.is_valid) {
                console.warn(`[OCR-REVERIFY] Rejecting invalid ${docType} on KYC service exception. Error: ${integrityCheck.error}`);
                throw new common_1.BadRequestException(`Document verification failed: The document was not recognized as a valid ${docType.toUpperCase().replace(/_/g, ' ')}. ` +
                    `Details: ${integrityCheck.error}. Please check your document.`);
            }
            kycResult = {
                document_type: docType,
                confidence_score: 50,
                is_valid: true,
                extracted_data: {},
                error: `AI verification service temporarily offline: ${aiError.message || 'Unknown error'}`
            };
        }
        const newStatus = kycResult.is_valid ? 'uploaded' : 'rejected';
        const verificationResult = {
            isValid: kycResult.is_valid,
            code: kycResult.is_valid ? 'AI_VERIFIED' : 'AI_REJECTED',
            confidence: kycResult.confidence_score,
            details: {
                message: kycResult.is_valid
                    ? 'Document re-verified by AI OCR.'
                    : kycResult.error || 'Verification failed',
                extractedFields: kycResult.extracted_data,
                document_validation: kycResult.document_validation,
                ocr_issues: kycResult.ocr_issues,
            },
        };
        await this.usersService.upsertUserDocument(userId, docType, {
            uploaded: true,
            filePath: doc.filePath,
            status: newStatus,
            verificationMetadata: verificationResult,
        });
        if (kycResult.is_valid &&
            kycResult.extracted_data &&
            Object.keys(kycResult.extracted_data).length > 0) {
            await this.usersService.updateExtractedDetails(userId, {
                documentVerified: true,
                ...(0, ocr_fields_util_1.maskSensitiveIds)(kycResult.extracted_data, docType),
            }, docType);
        }
        return {
            success: true,
            data: {
                docType,
                userId,
                isValid: kycResult.is_valid,
                confidence: kycResult.confidence_score,
                extractedFields: kycResult.extracted_data,
                reason: kycResult.error,
                newStatus,
                verification: verificationResult,
                ocrResult: {
                    isValid: kycResult.is_valid,
                    confidence: kycResult.confidence_score,
                    extractedFields: kycResult.extracted_data,
                    document_validation: kycResult.document_validation,
                    ocr_issues: kycResult.ocr_issues,
                },
            },
        };
    }
    async initiateDigilockerFlow(userId, docType, redirectUri) {
        if (!userId || !docType)
            throw new common_1.BadRequestException('userId and docType are required');
        const codeVerifier = crypto.randomBytes(32).toString('base64url');
        const codeChallenge = crypto
            .createHash('sha256')
            .update(codeVerifier)
            .digest('base64url');
        const backendUrl = process.env.BACKEND_URL || 'http://localhost:5000';
        const callbackUrl = process.env.DIGILOCKER_CALLBACK_URL ||
            backendUrl + '/api/digilocker/callback';
        const stateData = { userId, docType, redirectUri, codeVerifier };
        const state = Buffer.from(JSON.stringify(stateData))
            .toString('base64')
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');
        const authUrl = this.digilockerService.getAuthUrl(state, callbackUrl, codeChallenge);
        return { success: true, authUrl };
    }
    async viewDocument(userId, docType, bankId, res) {
        if (bankId) {
            const { data: consent } = await this.supabase.client
                .from('StudentBankConsent')
                .select('isGranted')
                .eq('studentId', userId)
                .eq('bankId', bankId)
                .maybeSingle();
            if (!consent || !consent.isGranted) {
                throw new common_1.ForbiddenException('Access denied: Explicit student consent is required for this bank to view this document.');
            }
            await this.supabase.client.from('data_access_logs').insert({
                accessedBy: bankId,
                applicationId: userId,
                action: `Viewed document type: ${docType}`,
                accessedAt: new Date().toISOString(),
            });
        }
        const docs = await this.usersService.getUserDocuments(userId);
        const doc = docs.find((d) => d.docType === docType);
        if (!doc || !doc.filePath)
            throw new common_1.NotFoundException('Document not found');
        if (doc.filePath.startsWith('in.gov.')) {
            const html = `<!DOCTYPE html><html><head><title>DigiLocker Record - ${doc.docName || doc.docType}</title>
<style>body{font-family:system-ui,sans-serif;background:#f0f2f5;display:flex;justify-content:center;padding:40px}.card{background:white;padding:40px;border-radius:12px;box-shadow:0 4px 6px rgba(0,0,0,.1);max-width:600px;width:100%;border-top:6px solid #82c91e}.badge{background:#e6fced;color:#12b842;padding:6px 12px;border-radius:20px;font-weight:600;font-size:14px}</style></head>
<body><div class="card"><h2>Digital Verification Record</h2><span class="badge">✓ Verified by DigiLocker</span>
<p><strong>Document:</strong> ${doc.docName || doc.docType}</p>
<p><strong>Reference:</strong> ${doc.filePath}</p></div></body></html>`;
            res.setHeader('Content-Type', 'text/html');
            return res.send(html);
        }
        try {
            const presignedUrl = await this.s3Service.getPresignedUrl(doc.filePath, 3600);
            return res.redirect(302, presignedUrl);
        }
        catch (err) {
            console.error('[VIEW] Failed to generate presigned URL:', err);
            throw new common_1.NotFoundException('Unable to retrieve document from storage.');
        }
    }
    async getPresignedViewUrl(userId, docType, bankId) {
        if (bankId) {
            const { data: consent } = await this.supabase.client
                .from('StudentBankConsent')
                .select('isGranted')
                .eq('studentId', userId)
                .eq('bankId', bankId)
                .maybeSingle();
            if (!consent || !consent.isGranted) {
                throw new common_1.ForbiddenException('Access denied: Explicit student consent is required for this bank to view this document.');
            }
            await this.supabase.client.from('data_access_logs').insert({
                accessedBy: bankId,
                applicationId: userId,
                action: `Generated preview link for document: ${docType}`,
                accessedAt: new Date().toISOString(),
            });
        }
        const docs = await this.usersService.getUserDocuments(userId);
        const doc = docs.find((d) => d.docType === docType);
        if (!doc || !doc.filePath)
            throw new common_1.NotFoundException('Document not found');
        const url = await this.s3Service.getPresignedUrl(doc.filePath, 3600);
        return { success: true, url, docType, filePath: doc.filePath };
    }
    async getUserDocuments(userId) {
        const documents = await this.usersService.getUserDocuments(userId);
        return { success: true, data: documents };
    }
    async deleteDocument(userId, docType) {
        const docs = await this.usersService.getUserDocuments(userId);
        const doc = docs.find((d) => d.docType === docType);
        if (doc?.filePath && !doc.filePath.startsWith('in.gov.')) {
            await this.s3Service.delete(doc.filePath);
        }
        await this.usersService.deleteUserDocument(userId, docType);
        return { success: true, message: 'Document deleted successfully' };
    }
    async addRequirement(userId, docType, docName) {
        if (!userId || !docType)
            throw new common_1.BadRequestException('userId and docType are required');
        const existing = (await this.usersService.getUserDocuments(userId)).find((d) => d.docType === docType);
        if (existing?.uploaded ||
            ['uploaded', 'verified'].includes(String(existing?.status || '').toLowerCase())) {
            return {
                success: true,
                message: 'Requirement already has an uploaded document',
                data: existing,
            };
        }
        const document = await this.usersService.upsertUserDocument(userId, docType, {
            uploaded: false,
            status: 'pending',
            verificationMetadata: {
                message: 'Requirement added by staff',
                docName: docName || docType,
            },
        });
        return {
            success: true,
            message: 'Requirement added successfully',
            data: document,
        };
    }
    async acceptDocument(docId) {
        if (!docId) {
            throw new common_1.BadRequestException('Document ID is required');
        }
        console.log(`[DOCUMENT-ACCEPT] Processing acceptance for docId: ${docId}`);
        try {
            const updatedDoc = await this.usersService.updateDocumentStatus(docId, 'verified');
            if (!updatedDoc) {
                throw new common_1.NotFoundException(`Document with ID ${docId} not found`);
            }
            console.log(`[DOCUMENT-ACCEPT] Document ${docId} accepted successfully`);
            return {
                success: true,
                message: 'Document accepted successfully',
                data: updatedDoc,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            console.error(`[DOCUMENT-ACCEPT] Error accepting document ${docId}:`, error.message);
            throw new common_1.BadRequestException(`Failed to accept document: ${error.message || 'Unknown error'}`);
        }
    }
    async rejectDocument(docId, rejectionReason) {
        if (!docId) {
            throw new common_1.BadRequestException('Document ID is required');
        }
        if (!rejectionReason || rejectionReason.trim().length === 0) {
            throw new common_1.BadRequestException('Rejection reason is required');
        }
        console.log(`[DOCUMENT-REJECT] Processing rejection for docId: ${docId}, reason: ${rejectionReason}`);
        try {
            const updatedDoc = await this.usersService.updateDocumentStatus(docId, 'rejected', rejectionReason.trim());
            if (!updatedDoc) {
                throw new common_1.NotFoundException(`Document with ID ${docId} not found`);
            }
            console.log(`[DOCUMENT-REJECT] Document ${docId} rejected successfully`);
            return {
                success: true,
                message: 'Document rejected successfully',
                data: updatedDoc,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            console.error(`[DOCUMENT-REJECT] Error rejecting document ${docId}:`, error.message);
            throw new common_1.BadRequestException(`Failed to reject document: ${error.message || 'Unknown error'}`);
        }
    }
    async sendDocumentToBank(userId, docType, docTitle, bankId, bankName, notes, studentName, applicationNumber) {
        if (!userId || !docType || !bankId) {
            throw new common_1.BadRequestException('userId, docType and bankId are required');
        }
        console.log(`[SEND-TO-BANK] userId=${userId} docType=${docType} bankName=${bankName}`);
        try {
            const docs = await this.usersService.getUserDocuments(userId);
            const doc = docs.find((d) => d.docType === docType);
            if (!doc || !doc.filePath) {
                throw new common_1.NotFoundException('Document not found or not yet uploaded.');
            }
            let presignedUrl = '';
            try {
                presignedUrl = await this.s3Service.getPresignedUrl(doc.filePath, 3600);
            }
            catch (s3Err) {
                console.warn(`[SEND-TO-BANK] Could not generate presigned URL: ${s3Err.message}`);
                presignedUrl = `/api/documents/view/${userId}/${docType}`;
            }
            const transmissionId = `DOC-${Date.now().toString(36).toUpperCase()}-${docType.toUpperCase().slice(0, 4)}`;
            try {
                await this.supabase.client.from('data_access_logs').insert({
                    accessedBy: bankId,
                    applicationId: userId,
                    action: `Staff sent document "${docTitle || docType}" to ${bankName}. Notes: ${notes || 'None'}. Ref: ${transmissionId}`,
                    accessedAt: new Date().toISOString(),
                });
            }
            catch (logErr) {
                console.warn(`[SEND-TO-BANK] Audit log insert failed (non-blocking): ${logErr.message}`);
            }
            return {
                success: true,
                message: `Document "${docTitle || docType}" sent to ${bankName} successfully`,
                data: {
                    transmissionId,
                    bankId,
                    bankName,
                    docType,
                    studentName,
                    applicationNumber,
                    presignedUrl,
                    expiresAt: new Date(Date.now() + 3600 * 1000).toISOString(),
                },
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException || error instanceof common_1.BadRequestException) {
                throw error;
            }
            console.error(`[SEND-TO-BANK] Error:`, error.message);
            throw new common_1.BadRequestException(`Failed to send document to bank: ${error.message || 'Unknown error'}`);
        }
    }
};
exports.DocumentController = DocumentController;
__decorate([
    (0, common_1.Post)('upload'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('file', {
        storage,
        limits: { fileSize: 10 * 1024 * 1024 },
        fileFilter: (req, file, cb) => {
            const ext = file.originalname.split('.').pop()?.toLowerCase();
            const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
            const isMimeValid = file.mimetype.match(/\/(jpg|jpeg|png|pdf)$/) || file.mimetype === 'application/octet-stream';
            const isExtValid = ext && allowedExtensions.includes(ext);
            if (isMimeValid || isExtValid) {
                cb(null, true);
            }
            else {
                cb(new common_1.BadRequestException('Unsupported file type. Only PDF, JPG, JPEG, and PNG files are allowed.'), false);
            }
        },
    })),
    __param(0, (0, common_1.UploadedFile)()),
    __param(1, (0, common_1.Body)('userId')),
    __param(2, (0, common_1.Body)('docType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "uploadFile", null);
__decorate([
    (0, common_1.Post)('ocr-reverify'),
    __param(0, (0, common_1.Body)('userId')),
    __param(1, (0, common_1.Body)('docType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "ocrReverify", null);
__decorate([
    (0, common_1.Post)('digilocker/initiate'),
    __param(0, (0, common_1.Body)('userId')),
    __param(1, (0, common_1.Body)('docType')),
    __param(2, (0, common_1.Body)('redirectUri')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "initiateDigilockerFlow", null);
__decorate([
    (0, common_1.Get)('view/:userId/:docType'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Param)('docType')),
    __param(2, (0, common_1.Query)('bankId')),
    __param(3, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, Object]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "viewDocument", null);
__decorate([
    (0, common_1.Get)('presigned-view/:userId/:docType'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Param)('docType')),
    __param(2, (0, common_1.Query)('bankId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "getPresignedViewUrl", null);
__decorate([
    (0, common_1.Get)(':userId'),
    __param(0, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "getUserDocuments", null);
__decorate([
    (0, common_1.Delete)(':userId/:docType'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Param)('docType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "deleteDocument", null);
__decorate([
    (0, common_1.Post)('requirement'),
    __param(0, (0, common_1.Body)('userId')),
    __param(1, (0, common_1.Body)('docType')),
    __param(2, (0, common_1.Body)('docName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "addRequirement", null);
__decorate([
    (0, common_1.Post)(':docId/accept'),
    __param(0, (0, common_1.Param)('docId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "acceptDocument", null);
__decorate([
    (0, common_1.Post)(':docId/reject'),
    __param(0, (0, common_1.Param)('docId')),
    __param(1, (0, common_1.Body)('rejectionReason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "rejectDocument", null);
__decorate([
    (0, common_1.Post)('send-to-bank'),
    __param(0, (0, common_1.Body)('userId')),
    __param(1, (0, common_1.Body)('docType')),
    __param(2, (0, common_1.Body)('docTitle')),
    __param(3, (0, common_1.Body)('bankId')),
    __param(4, (0, common_1.Body)('bankName')),
    __param(5, (0, common_1.Body)('notes')),
    __param(6, (0, common_1.Body)('studentName')),
    __param(7, (0, common_1.Body)('applicationNumber')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String, String, String, String]),
    __metadata("design:returntype", Promise)
], DocumentController.prototype, "sendDocumentToBank", null);
exports.DocumentController = DocumentController = __decorate([
    (0, common_1.Controller)('documents'),
    __metadata("design:paramtypes", [users_service_1.UsersService,
        digilocker_service_1.DigilockerService,
        document_verification_service_1.DocumentVerificationService,
        kyc_service_1.KycService,
        s3_service_1.S3Service,
        supabase_service_1.SupabaseService])
], DocumentController);
//# sourceMappingURL=document.controller.js.map