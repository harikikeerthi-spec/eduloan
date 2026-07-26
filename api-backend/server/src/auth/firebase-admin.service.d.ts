import { OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { ConfigService } from '@nestjs/config';
export declare class FirebaseAdminService implements OnModuleInit {
    private configService;
    constructor(configService: ConfigService);
    onModuleInit(): void;
    getAdmin(): typeof admin;
}
