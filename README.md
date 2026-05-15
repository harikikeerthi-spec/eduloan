# VidhyaLoan - Premium Education Financing

VidhyaLoan is a comprehensive platform designed to simplify the education financing process for students. It combines a powerful mobile application for users with a robust backend to handle loan applications, university comparisons, and AI-driven tools.

## 🚀 Features

- **Google Sign-In Authentication**: Secure and seamless login using Firebase and Google.
- **AI-Powered Tools**:
  - **Eligibility Checker**: Determine your loan eligibility instantly.
  - **Grade Converter**: Convert your grades across different international systems.
  - **University Shortlisting**: Get AI-driven recommendations for universities.
  - **Visa Interview Simulator**: Practice for your visa interview with an AI mentor.
- **Loan Management**: Apply for and track your education loans in real-time.
- **Community & Mentors**: Connect with mentors and other students through forums and events.
- **EMI Calculator**: Calculate your monthly repayments easily.

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **Backend**: NestJS (located in `api-backend/server`)
- **Database**: Supabase (via Prisma)
- **Authentication**: Firebase Auth & Google Sign-In
- **AI Services**: Groq / OpenAI / Custom AI services

## 📋 Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Node.js**: [Install Node.js](https://nodejs.org/) (v16+ recommended)
- **Firebase Account**: For Google Sign-In and Cloud messaging.

## ⚙️ Setup & Configuration

### 1. Google Sign-In (Android)
To enable Google Sign-In on Android, you must register your debug SHA-1 fingerprint in the Firebase Console:
1. Run `./android/gradlew signingReport` to get your SHA-1.
2. Add the fingerprint to your Android app in the Firebase Console.
3. Download the updated `google-services.json` and place it in `android/app/`.

### 2. Backend Environment Variables
Create a `.env` file in `api-backend/server/` based on `.env.example`:
```env
DATABASE_URL="your_supabase_postgresql_url"
DIRECT_URL="your_supabase_direct_url"
GROQ_API_KEY="your_groq_api_key"
SUPABASE_URL="your_supabase_project_url"
SUPABASE_KEY="your_supabase_anon_key"
```

## 🏃 Running the Project

### Start the Backend
```bash
cd api-backend/server
npm install
npx prisma generate
npm run start:dev
```

### Start the Flutter App
```bash
flutter pub get
flutter run
```

## 🤝 Contributing
1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
