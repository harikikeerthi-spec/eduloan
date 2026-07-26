export declare class S3Service {
    private readonly s3Client;
    private readonly bucketName;
    private readonly logger;
    constructor();
    uploadFile(file: Express.Multer.File, key: string): Promise<string>;
    getPresignedUrl(key: string, expiresInSeconds?: number): Promise<string>;
    deleteFile(key: string): Promise<void>;
}
