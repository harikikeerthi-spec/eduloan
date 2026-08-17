# VidyaLoans: Mobile App & Backend Security Architecture Blueprint

> **Document Version:** 1.0.0  
> **Target Platforms:** Flutter (Android & iOS) + NestJS Backend  
> **Compliance Standards:** RBI Digital Lending Guidelines, DPDP Act (2023), OWASP Mobile Top 10  
> **Date:** August 15, 2026  

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Web vs. Mobile Security: Why Mobile Doesn't Need CSRF](#2-web-vs-mobile-security-why-mobile-doesnt-need-csrf)
3. [Mobile Application Security Architecture (Flutter)](#3-mobile-application-security-architecture-flutter)
   - 3.1 Hardware-Backed Keystore Token Storage
   - 3.2 Screen Capture & Recording Prevention (FLAG_SECURE)
   - 3.3 Code Obfuscation & Reverse-Engineering Defense (R8/ProGuard)
   - 3.4 Strict HTTPS & Network Security Configuration
   - 3.5 SSL Certificate Pinning
   - 3.6 Biometric Authentication & Session Timeout
4. [Backend API & Server Security Architecture (NestJS)](#4-backend-api--server-security-architecture-nestjs)
   - 4.1 JWT Bearer Token Cryptographic Verification
   - 4.2 Rate Limiting & Anti-DDoS Throttling
   - 4.3 HTTP Security Headers (Helmet)
   - 4.4 Global Input Validation & Injection Defense (ValidationPipe)
   - 4.5 Token Blacklisting on Logout & Account Deletion
   - 4.6 File Upload MIME & Malware Sanitization
5. [Data Privacy & Banking Compliance (RBI & DPDP Act)](#5-data-privacy--banking-compliance-rbi--dpdp-act)
   - 5.1 Personally Identifiable Information (PII) Masking
   - 5.2 At-Rest Document Encryption & Presigned URLs
   - 5.3 Immutable Security Audit Trails
6. [Implementation Action Plan & Code Snippets](#6-implementation-action-plan--code-snippets)

---

## 1. Executive Summary

VidyaLoans processes sensitive student loan applications, identity documents (Passports, Aadhaar, PAN), academic records, and financial sanctions. Protecting this data requires a defense-in-depth security model spanning the Flutter mobile client, network transit layer, NestJS application backend, and encrypted cloud storage.

This document outlines the complete architectural standards and implementation specifications required to achieve bank-grade security for the VidyaLoans mobile application.

---

## 2. Web vs. Mobile Security: Why Mobile Doesn't Need CSRF

### The Web Vulnerability (Why Web Uses CSRF Tokens)
In standard web browsers, session credentials (cookies) are automatically attached to every HTTP request made to a domain. If a user visits an external malicious website while logged in, that website can secretly trigger write operations against `vidyaloans.com` using the browser's ambient cookie session. To prevent this **Cross-Site Request Forgery (CSRF)**, web applications require anti-CSRF tokens and `SameSite` cookie policies.

### The Mobile Architecture (Why Mobile is Immune to CSRF)
1. **Operating System Sandboxing:** Android and iOS run each application in a strictly isolated native sandbox with dedicated user IDs and file system permissions.
2. **Explicit Authorization Headers:** Native mobile applications do not rely on browser cookie jars. Every authenticated API request explicitly attaches a cryptographic JWT token via the `Authorization: Bearer <token>` HTTP header.
3. **Cross-App Isolation:** An external app installed on the user's phone cannot intercept, inject, or forge requests inside the VidyaLoans application runtime.

---

## 3. Mobile Application Security Architecture (Flutter)

```
┌────────────────────────────────────────────────────────────────────────┐
│                      FLUTTER CLIENT APPLICATION                        │
│                                                                        │
│   ┌───────────────────────────┐      ┌─────────────────────────────┐   │
│   │   Android Keystore /      │      │   FLAG_SECURE               │   │
│   │   iOS Keychain Storage    │      │   (Anti-Screen Recording)   │   │
│   └─────────────┬─────────────┘      └──────────────┬──────────────┘   │
│                 │                                   │                  │
│                 ▼                                   ▼                  │
│   ┌───────────────────────────┐      ┌─────────────────────────────┐   │
│   │   ProGuard / R8           │      │   SSL Certificate           │   │
│   │   Code Obfuscation        │      │   Pinning Layer             │   │
│   └─────────────┬─────────────┘      └──────────────┬──────────────┘   │
└─────────────────┼───────────────────────────────────┼──────────────────┘
                  │                                   │
                  └───────────────► HTTPS ◄───────────┘
                               (TLS 1.3)
```

### 3.1 Hardware-Backed Keystore Token Storage
* **Vulnerability:** Plaintext local storage (e.g., standard `SharedPreferences` or SQLite) can be extracted if an Android device is rooted or accessed via ADB.
* **Architecture:** Use `flutter_secure_storage` to encrypt tokens with AES-256 using keys stored in the **Android Keystore System** (backed by hardware TEE/StrongBox) and **iOS Keychain**.

### 3.2 Screen Capture & Recording Prevention (FLAG_SECURE)
* **Vulnerability:** Spyware, screen-sharing apps, or background recorders can capture sensitive financial documents (bank statements, tax returns, passport copies).
* **Architecture:** Enable `FLAG_SECURE` on Android and screen-shielding on iOS across sensitive screens:
  - Document Vault (`document_vault_page.dart`)
  - Loan Details & Sanction Letters (`my_loans_page.dart`)
  - Complete Profile & KYC screens (`complete_profile_page.dart`)

### 3.3 Code Obfuscation & Reverse-Engineering Defense (R8/ProGuard)
* **Vulnerability:** Attackers decompiling the APK with tools like `jadx` can inspect API routes, business logic, and cryptographic constants.
* **Architecture:** Enable R8 shrinking and ProGuard bytecode obfuscation in release builds:
  - Renames classes, methods, and variables into non-human-readable identifiers (`a`, `b`, `c`).
  - Strips unused code, classes, and debug logging statements.

### 3.4 Strict HTTPS & Network Security Configuration
* **Vulnerability:** Cleartext HTTP traffic is susceptible to packet sniffing and ISP/public Wi-Fi manipulation.
* **Architecture:** In `android/app/src/main/res/xml/network_security_config.xml`, enforce:
  - `cleartextTrafficPermitted="false"` for all release builds.
  - TLS 1.2+ minimum protocol negotiation.

### 3.5 SSL Certificate Pinning
* **Vulnerability:** An attacker using proxy tools (Burp Suite, Charles Proxy) or a compromised root CA on a device can intercept API traffic.
* **Architecture:** Pin the SHA-256 fingerprint of the `api.vidyaloans.com` TLS certificate inside the HTTP client layer.

### 3.6 Biometric Authentication & Session Timeout
* **Architecture:** Implement optional Face ID / Fingerprint unlock (`local_auth`) when the app is placed in the background for more than 5 minutes.

---

## 4. Backend API & Server Security Architecture (NestJS)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        NESTJS API BACKEND                              │
│                                                                        │
│  Incoming Request                                                      │
│        │                                                               │
│        ▼                                                               │
│  ┌───────────────────────────┐ ──► Rejects bursts / brute-force        │
│  │ @nestjs/throttler         │                                         │
│  └─────────────┬─────────────┘                                         │
│                ▼                                                       │
│  ┌───────────────────────────┐ ──► Enforces CSP, HSTS, X-Frame-Options │
│  │ Helmet Security Headers   │                                         │
│  └─────────────┬─────────────┘                                         │
│                ▼                                                       │
│  ┌───────────────────────────┐ ──► Validates JWT Signature & Revocation│
│  │ Auth & Role Guards        │                                         │
│  └─────────────┬─────────────┘                                         │
│                ▼                                                       │
│  ┌───────────────────────────┐ ──► Sanitizes fields, strips injection  │
│  │ ValidationPipe            │                                         │
│  └─────────────┬─────────────┘                                         │
│                ▼                                                       │
│      Protected Controller                                              │
└────────────────────────────────────────────────────────────────────────┘
```

### 4.1 JWT Bearer Token Cryptographic Verification
* Every incoming protected request is verified against the server's `JWT_SECRET` key using HMAC SHA-256 or RSA-256.
* Tokens have short lifespans (e.g., 24 hours access token, 30 days refresh token).

### 4.2 Rate Limiting & Anti-DDoS Throttling
* Protect sensitive endpoints from brute force and automated spam using `@nestjs/throttler`:
  - **OTP Send/Verify:** Maximum 5 attempts per 10 minutes per phone/IP.
  - **Login / Register:** Maximum 10 attempts per minute.
  - **Community & Chat:** Maximum 30 messages per minute.
  - **General API:** Maximum 120 requests per minute per IP.

### 4.3 HTTP Security Headers (Helmet)
* Integrates `helmet` middleware to protect HTTP responses:
  - `Strict-Transport-Security` (HSTS): Forces browsers and clients to use HTTPS.
  - `X-Content-Type-Options: nosniff`: Prevents MIME-type sniffing.
  - `X-Frame-Options: DENY`: Prevents clickjacking.
  - `Content-Security-Policy`: Restricts resource origins.

### 4.4 Global Input Validation & Injection Defense (ValidationPipe)
* Enforce strict class-validator DTOs:
  ```typescript
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,              // Strips non-whitelisted payload properties
    forbidNonWhitelisted: true,   // Rejects requests with rogue injection parameters
    transform: true,
  }));
  ```

### 4.5 Token Blacklisting on Logout & Account Deletion
* When a user selects **"Log Out"** or **"Delete Account"**, the server writes the token's unique JTI / signature into a revocation cache (Redis or persistent DB table) to immediately invalidate it prior to its natural expiration time.

### 4.6 File Upload MIME & Malware Sanitization
* Validate uploaded documents by checking magic byte headers (`%PDF` for PDFs, `FF D8 FF` for JPEGs) rather than trusting user-supplied file extensions.
* Enforce strict file size caps (e.g., max 10MB per document).

---

## 5. Data Privacy & Banking Compliance (RBI & DPDP Act)

| Requirement | Technical Control | Status in VidyaLoans |
|---|---|:---:|
| **PII Data Masking** | Mask phone numbers (`XXXXXXXXXX`) and government IDs in UI & logs. | ✅ Implemented |
| **At-Rest Cloud Encryption** | Encrypt S3 / Supabase storage buckets using AES-256 server-side encryption. | ✅ Configured |
| **Time-Limited Presigned URLs** | Document download links expire after 15 minutes. | ✅ Enforced |
| **Right to Erasure (Account Deletion)** | Complete purge of user records & document references upon verified deletion request. | ✅ Implemented |
| **Audit Logs** | Immutable logs tracking staff assignments, document uploads, and loan status changes. | ✅ Active |

---

## 6. Implementation Action Plan & Code Snippets

### Step 1: Backend Security Hardening (`api-backend/server/src/main.ts`)

```typescript
import helmet from 'helmet';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // 1. Security Headers
  app.use(helmet());

  // 2. Global Input Sanitization & Parameter Validation
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));

  // 3. API Prefix & CORS
  app.setGlobalPrefix('api');
  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  const port = process.env.PORT || 5000;
  await app.listen(port, '0.0.0.0');
}
```

### Step 2: Rate Limiting Configuration (`api-backend/server/src/app.module.ts`)

```typescript
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [
    ThrottlerModule.forRoot([{
      ttl: 60000, // 60 seconds
      limit: 100, // 100 requests per minute
    }]),
    // ...other modules
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
```

### Step 3: Hardware Keystore Storage in Flutter (`lib/services/auth_service.dart`)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
```

### Step 4: ProGuard Obfuscation (`android/app/build.gradle`)

```groovy
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

## 7. Summary & Certification Checklist

| Security Layer | Implemented Mechanism | Verification Method |
|---|---|---|
| **Client Authentication** | JWT Bearer Tokens in HTTP Headers | Automated NestJS `UserGuard` tests |
| **Client Storage** | Hardware-backed Keystore / Keychain | `flutter_secure_storage` encrypted shared preferences |
| **Transit Encryption** | TLS 1.3 HTTPS + SSL Pinning | Network inspection validation |
| **API Protection** | Helmet + Throttling + ValidationPipe | Security vulnerability scan |
| **Privacy Compliance** | Phone / PII Masking + Timed Presigned URLs | RBI compliance audit |

*Document compiled and certified for the VidyaLoans Engineering & Security Team.*
