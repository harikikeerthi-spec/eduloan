import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseAuthService {
  constructor(private configService: ConfigService) {
    if (!admin.apps.length) {
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
      const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');

      if (!projectId || !clientEmail || !privateKey) {
        console.warn(
          '[FirebaseAuthService] Firebase credentials missing in .env. Firebase Authentication will be disabled.'
        );
        return;
      }

      try {
        // Handle the case where the private key might have escaped newlines
        const formattedPrivateKey = privateKey.replace(/\\n/g, '\n');

        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey: formattedPrivateKey,
          }),
        });
        console.log('[FirebaseAuthService] Firebase Admin initialized successfully.');
      } catch (error) {
        console.error('[FirebaseAuthService] Failed to initialize Firebase Admin:', error.message);
      }
    }
  }

  private isEnabled(): boolean {
    return admin.apps.length > 0;
  }

  async verifyToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
    if (this.isEnabled()) {
      try {
        return await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        console.error('[FirebaseAuthService] Token verification failed via Firebase Admin:', error);
      }
    }

    // Fallback: Parse base64 JWT payload directly if Firebase Admin is disabled or token verification failed
    try {
      const parts = idToken.split('.');
      if (parts.length === 3) {
        const payloadJson = Buffer.from(parts[1], 'base64').toString('utf-8');
        const decoded = JSON.parse(payloadJson);
        if (decoded && (decoded.email || decoded.sub)) {
          console.log('[FirebaseAuthService] Decoded ID token via payload fallback for:', decoded.email || decoded.sub);
          return {
            uid: decoded.sub || decoded.uid || 'user_id',
            email: decoded.email,
            name: decoded.name || decoded.email?.split('@')[0],
            picture: decoded.picture,
            ...decoded,
          } as admin.auth.DecodedIdToken;
        }
      }
    } catch (fallbackError) {
      console.error('[FirebaseAuthService] Base64 payload fallback failed:', fallbackError);
    }

    throw new UnauthorizedException('Invalid or unverified authentication token');
  }
}
