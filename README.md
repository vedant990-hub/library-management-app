📚 Library Management App

A modern Library Management System built using Flutter & Firebase, designed to digitize book borrowing, reservations, wallet tracking, and admin management with a clean and responsive UI.

🚀 Overview

This application replaces traditional manual library tracking systems with a scalable, cloud-powered digital solution.

It supports:

Role-based access (Admin & User)

Book management

Borrowing & reservation workflows

Wallet-based fine handling

QR-based identification

Firebase Cloud Functions backend

Cross-platform support

🔥 Core Features
👤 User Panel

Secure Email & Google Authentication

Digital Library ID (QR)

Browse & discover books

Reserve books

Borrow & return books

Wallet balance tracking

Borrow history

Fine management

🛠 Admin Panel

Add / Edit / Delete books

Manage users

QR-based user scanning

Borrow & return control

Overdue tracking

Analytics dashboard

Financial summary (Total Wallet Balance)

🏗 Tech Stack
Frontend

Flutter

Provider (State Management)

Backend

Firebase Authentication

Cloud Firestore

Firebase Cloud Functions

Security

Firestore Security Rules

Platforms

Android

iOS

Web

Windows

macOS

Linux

📱 App Screenshots
🔐 Login Screen

👤 User Dashboard

🛠 Admin Dashboard

📂 Project Structure
lib/
 ├── models/
 ├── providers/
 ├── screens/
 ├── widgets/
 ├── theme/
 └── main.dart

functions/
 ├── index.js
 ├── package.json
 └── package-lock.json

firestore.rules
⚙️ Installation
1️⃣ Clone Repository
git clone https://github.com/vedant990-hub/library-management-app.git
cd library-management-app
2️⃣ Install Dependencies
flutter pub get
3️⃣ Setup Firebase

Create a Firebase project

Enable:

Authentication

Firestore

Cloud Functions

Add google-services.json to:

android/app/

Add GoogleService-Info.plist to:

ios/Runner/
4️⃣ Install Firebase Functions
cd functions
npm install
cd ..
5️⃣ Run App
flutter run
📦 Build Release APK
flutter build apk --release

Output:

build/app/outputs/flutter-apk/app-release.apk
☁️ Deploy Backend
firebase deploy --only functions
firebase deploy --only firestore:rules
🔐 Security

Role-based Firestore access control

Firebase Authentication

Cloud Functions for backend validation

Wallet transaction handling logic

📌 Future Improvements

Push notifications

Advanced analytics charts

Payment gateway integration

Multi-library support

Role-based granular permissions

👨‍💻 Author

Vedant Pawar
GitHub: https://github.com/vedant990-hub

📜 License

This project is developed for educational and demonstration purposes.