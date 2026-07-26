export declare class S3Service {
    private readonly logger;
    private readonly client;
    private readonly bucket;
    private readonly region;
    constructor();
    upload(key: string, body: Buffer, contentType: string): Promise<string>;
    getPresignedUrl(key: string, expiresIn?: number): Promise<string>;
    delete(key: string): Promise<void>;
    buildKey(userId: string, docType: string, originalname: string): string;
}
