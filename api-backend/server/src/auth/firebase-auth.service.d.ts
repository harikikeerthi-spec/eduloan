import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
export declare class FirebaseAuthService {
    private configService;
    constructor(configService: ConfigService);
    private isEnabled;
    verifyToken(idToken: string): Promise<admin.auth.DecodedIdToken>;
}
