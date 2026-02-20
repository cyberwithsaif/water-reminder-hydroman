# Hydroman 💧

**A Premium, Smart Hydration Reminder App for Android.**

Hydroman is a feature-rich water tracking and reminder application designed to help users maintain their daily hydration goals through intelligent scheduling, persistent data synchronization, and a beautiful, dynamic user interface.

## 🚀 Key Features

- **Smart Reminders**: Intelligent notification scheduling that persists even after app kills and device reboots (Direct Boot aware).
- **Dynamic Water Fill**: A stunning Home screen progress indicator with smooth, wavy water animations reflecting real-time intake.
- **Persistent Deletions**: Robust local blocklist and server-side hard-delete synchronization to ensure deleted data never reappears.
- **Offline First**: Full offline support powered by Hive database, with seamless cloud synchronization when back online.
- **Analytics & History**: Detailed drinking logs with a calendar-based history view.
- **Smart Muting**: Advanced night-mute settings to ensure reminders only hit when you're awake.
- **Secure Auth**: Phone-based authentication with OTP verification.

## 🛠️ Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Flutter Riverpod
- **Local Persistence**: Hive (Key-Value Storage)
- **Networking**: Http (REST API)
- **Architecture**: Domain-Driven Design (DDD) inspired Repository/Provider pattern.
- **Animations**: Custom Painters & Animation Controllers.

## 📦 Project Structure

```text
lib/
├── core/               # Theme, constants, and global widgets
├── data/               # Models and Repositories (Hive integration)
├── features/           # UI features (Home, Analytics, Settings, etc.)
│   ├── home/           # Wave animations and daily tracking
│   ├── reminders/      # Notification scheduling logic
│   └── ...
├── providers/          # Riverpod state management
└── services/           # Api, Notifications, and Sync services
```

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- An Android Device or Emulator

### Configuration
1. **Clone the repository**:
   ```bash
   git clone https://github.com/cyberwithsaif/water-reminder-hydroman.git
   cd water-reminder-hydroman
   ```

2. **Environment Variables**:
   The app uses environment variables for build-time configuration. Define your API base URL:
   ```bash
   flutter run --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

## 📝 Troubleshooting Notifications
If reminders are not firing in the background:
1. Go to **Settings > Troubleshooting**.
2. Tap **Test Background Notification** and immediately close the app.
3. Tap **Battery Optimization** to exempt Hydroman from system throttling.

## 🛡️ License
Copyright (c) 2026 Saif. All rights reserved.
