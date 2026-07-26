import { ConfigService } from '@nestjs/config';
export declare class TwilioService {
    private configService;
    private readonly logger;
    private client;
    constructor(configService: ConfigService);
    sendWhatsAppMessage(to: string, body: string): Promise<any>;
}
