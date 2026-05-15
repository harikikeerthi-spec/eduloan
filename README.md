# VidhyaLoan - Premium Education Financing Platform

![VidhyaLoan](https://img.shields.io/badge/VidhyaLoan-Mobile%20%26%20Backend-blueviolet?style=for-the-badge&logo=flutter)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![NestJS](https://img.shields.io/badge/NestJS-11+-E0234E?style=for-the-badge&logo=nestjs)
![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?style=for-the-badge&logo=firebase)
![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?style=for-the-badge&logo=supabase)

A professional-grade, multi-platform solution for education financing. VidhyaLoan provides students with AI-powered tools, university comparisons, and a seamless loan application experience, backed by a high-performance NestJS server.

---

### 🚀 Key Features

#### 📱 Mobile App (Flutter)
- **AI-Powered Decision Support**:
  - **Eligibility Checker**: Instant verification of loan eligibility.
  - **Grade Converter**: Seamless conversion between international grading systems.
  - **University Shortlisting**: Personalized AI recommendations for your academic profile.
  - **Visa Interview Simulator**: Interactive AI-led practice sessions.
- **Loan Lifecycle Management**: Complete tracking from application to disbursement.
- **Smart Tools**: Professional EMI calculators and university comparison engines.
- **Community Hub**: Integrated forums, mentorship programs, and event tracking.

#### ⚙️ Backend (NestJS)
- **Secure Authentication**: Combined Firebase & Google Sign-In with robust session management.
- **Scalable Architecture**: Modular NestJS design with Prisma ORM for type-safe database access.
- **AI Integrations**: Native support for Groq and OpenAI models.
- **Real-time Synchronization**: Instant updates across mobile and admin interfaces.

---

### 🛠️ Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Mobile** | **Flutter / Dart** | Cross-platform mobile development. |
| **Backend** | **NestJS 11** | Enterprise-grade Node.js framework. |
| **Database** | **Supabase / PostgreSQL** | Scalable relational database. |
| **Auth** | **Firebase & Google** | Secure, multi-provider authentication. |
| **ORM** | **Prisma** | Modern database toolkit. |
| **AI Engine** | **Groq / Llama 3** | High-speed LLM integration. |

---

### 📂 Project Structure

```text
Vidhyaloan/
├── lib/                    # 📱 Flutter Frontend
│   ├── models/             # Data structures
│   ├── pages/              # UI screens & navigation
│   ├── services/           # API & Business logic
│   └── widgets/            # Reusable UI components
├── api-backend/            # ⚙️ NestJS Backend
│   ├── server/             # Core server logic
│   │   ├── src/            # Business modules (Auth, AI, Loan)
│   │   └── prisma/         # Database schema & migrations
│   └── frontend/           # Admin/Internal Web interfaces
├── android/                # Android-specific configuration
└── assets/                 # App images, fonts, and icons
```

---

### 🚦 Quick Start

#### 1. Setup Backend
```bash
cd api-backend/server
npm install
# Configure .env with Supabase & AI keys
npx prisma generate
npm run start:dev
```

#### 2. Setup Flutter
```bash
# Ensure you have registered your SHA-1 in Firebase Console
# and placed the updated google-services.json in android/app/
flutter pub get
flutter run
```

---

### 🔧 Configuration Guide

#### Google Sign-In (Android)
To resolve `ApiException 16`, ensure your **SHA-1 fingerprint** is correctly registered in the Firebase Console and bundled in the `google-services.json`.

**Get your SHA-1:**
```powershell
./android/gradlew signingReport
```

#### Environment Variables
Ensure your `api-backend/server/.env` contains:
- `DATABASE_URL` / `DIRECT_URL` (Supabase)
- `GROQ_API_KEY` (AI Tools)
- `SUPABASE_URL` / `SUPABASE_KEY`

---

## 📄 License
This project is UNLICENSED.

---
*Built with ❤️ for the future of Education Financing.*
