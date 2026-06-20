"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var S3Service_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.S3Service = void 0;
const common_1 = require("@nestjs/common");
const client_s3_1 = require("@aws-sdk/client-s3");
const s3_request_presigner_1 = require("@aws-sdk/s3-request-presigner");
let S3Service = S3Service_1 = class S3Service {
    logger = new common_1.Logger(S3Service_1.name);
    client;
    bucket;
    region;
    constructor() {
        const rawRegion = (process.env.AWS_REGION || 'us-east-1').trim();
        const regionMatch = rawRegion.match(/[a-z]{2}-[a-z]+-\d/i);
        this.region = regionMatch ? regionMatch[0].toLowerCase() : 'us-east-1';
        this.bucket = (process.env.AWS_S3_BUCKET_NAME || '').trim();
        const accessKeyId = (process.env.AWS_ACCESS_KEY_ID || '').trim();
        const secretAccessKey = (process.env.AWS_SECRET_ACCESS_KEY || '').trim();
        this.logger.log(`[S3Service] Initializing. Region: ${this.region} (parsed from "${rawRegion}"), Bucket: ${this.bucket}`);
        this.client = new client_s3_1.S3Client({
            region: this.region,
            credentials: {
                accessKeyId,
                secretAccessKey,
            },
        });
        if (!this.bucket) {
            this.logger.warn('[S3Service] AWS_S3_BUCKET_NAME is not set. S3 operations will fail.');
        }
    }
    async upload(key, body, contentType) {
        this.logger.log(`[S3Service] Uploading: ${key} (${contentType})`);
        await this.client.send(new client_s3_1.PutObjectCommand({
            Bucket: this.bucket,
            Key: key,
            Body: body,
            ContentType: contentType,
        }));
        this.logger.log(`[S3Service] Uploaded successfully: ${key}`);
        return key;
    }
    async getPresignedUrl(key, expiresIn = 3600) {
        const command = new client_s3_1.GetObjectCommand({
            Bucket: this.bucket,
            Key: key,
        });
        return (0, s3_request_presigner_1.getSignedUrl)(this.client, command, { expiresIn });
    }
    async delete(key) {
        this.logger.log(`[S3Service] Deleting: ${key}`);
        try {
            await this.client.send(new client_s3_1.DeleteObjectCommand({
                Bucket: this.bucket,
                Key: key,
            }));
            this.logger.log(`[S3Service] Deleted: ${key}`);
        }
        catch (err) {
            this.logger.error(`[S3Service] Delete failed for key ${key}:`, err);
        }
    }
    buildKey(userId, docType, originalname) {
        const sanitizedName = originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
        return `documents/${userId}/${docType}/${Date.now()}-${sanitizedName}`;
    }
};
exports.S3Service = S3Service;
exports.S3Service = S3Service = S3Service_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], S3Service);
//# sourceMappingURL=s3.service.js.map