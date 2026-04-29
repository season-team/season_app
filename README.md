# Season App 🌍

A comprehensive Flutter mobile application for travel and group coordination with real-time location tracking, group management, and emergency SOS features.

## 📱 Overview

Season App is a cross-platform mobile application built with Flutter that enables users to create and manage travel groups, track locations in real-time, share QR codes, send emergency alerts, and coordinate travel activities seamlessly.

## ✨ Features

### 🔐 Authentication
- User registration and login
- OTP verification system
- Password reset functionality
- Social authentication support

### 👥 Group Management
- Create and manage travel groups
- Join groups via QR code scanning
- Real-time member location tracking
- Group member management
- Group details and settings

### 📍 Location Services
- Real-time location tracking
- Background location services
- Google Maps integration
- Distance calculation between members
- Location sharing

### 🚨 Emergency Features
- SOS emergency alert system
- Real-time emergency notifications
- Group-wide emergency broadcasts

### 🔔 Notifications
- Firebase Cloud Messaging (FCM)
- Push notifications
- Local notifications
- Background notification handling

### 🌐 Internationalization
- Multi-language support (English/Arabic)
- RTL (Right-to-Left) layout support
- Dynamic locale switching

### 🎨 User Interface
- Modern and clean UI design
- Custom themes (Light/Dark mode)
- Responsive design
- Smooth animations
- Custom widgets and components

### 📦 Additional Features
- QR code generation and scanning
- Profile management with avatar selection
- Travel bag/packing features
- Vendor integration
- File picker and image picker
- Screenshot and sharing capabilities
- WebView integration

## 🛠️ Technologies & Tools

### Core Framework
- **Flutter** 3.9.2+
- **Dart** SDK

### State Management
- **Riverpod** 3.0.3 - State management and dependency injection

### Navigation
- **GoRouter** 16.2.5 - Declarative routing

### Backend & Services
- **Firebase Core** 4.2.0
- **Firebase Cloud Messaging** 16.0.3
- **Dio** 5.9.0 - HTTP client

### Location & Maps
- **Google Maps Flutter** 2.10.0
- **Flutter Map** 7.0.2
- **Geolocator** 13.0.2
- **Flutter Background Service** 5.0.12

### UI & Media
- **Cached Network Image** 3.4.1
- **Flutter SVG** 2.0.10+1
- **Image Picker** 1.2.0
- **Mobile Scanner** 5.2.3 - QR/Barcode scanning
- **QR Flutter** 4.1.0 - QR code generation

### Storage & Preferences
- **Shared Preferences** 2.5.3
- **Path Provider** 2.1.5

### Utilities
- **Permission Handler** 11.3.1
- **Connectivity Plus** 7.0.0
- **Country Code Picker** 3.4.1
- **Pinput** 5.0.2 - PIN input widget
- **Share Plus** 10.1.3
- **URL Launcher** 6.3.1
- **File Picker** 8.1.3
- **Screenshot** 3.0.0
- **WebView Flutter** 4.10.0

### Localization
- **Flutter Localizations**
- **Intl** - Internationalization utilities
- **Intl Utils** 2.8.11

## 📁 Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App constants (colors, assets, endpoints)
│   ├── errors/             # Error handling
│   ├── localization/      # Localization setup
│   ├── router/            # Navigation and routing
│   ├── services/          # Core services (Firebase, storage, etc.)
│   ├── themes/            # App themes and styling
│   └── utils/             # Utility functions
├── features/               # Feature modules
│   ├── auth/              # Authentication feature
│   ├── bag/               # Travel bag feature
│   ├── groups/            # Group management feature
│   ├── home/              # Home screen feature
│   ├── profile/           # User profile feature
│   ├── reminders/         # Reminders feature
│   └── vendor/            # Vendor integration feature
├── shared/                 # Shared resources
│   ├── helpers/           # Helper functions
│   ├── providers/         # Shared providers
│   └── widgets/           # Reusable widgets
└── main.dart              # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account (for backend services)
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/season_app.git
   cd season_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` file to `android/app/`
   - Add your `GoogleService-Info.plist` file to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Configure Google Maps**
   - Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`
   - Add your Google Maps API key to `ios/Runner/AppDelegate.swift`

5. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

The project follows **Clean Architecture** principles with:

- **Repository Pattern** - Data abstraction layer
- **Provider Pattern** - State management with Riverpod
- **Feature-based Structure** - Organized by features/modules
- **Separation of Concerns** - Clear separation between UI, business logic, and data

### Architecture Layers

1. **Presentation Layer** - UI components, screens, widgets
2. **Domain Layer** - Business logic, controllers, providers
3. **Data Layer** - Repositories, data sources, models

## 🔧 Configuration

### Environment Setup

- Update API endpoints in `lib/core/constants/api_endpoints.dart`
- Configure app colors in `lib/core/constants/app_colors.dart`
- Set up localization files in `lib/l10n/`

### Firebase Setup

1. Create a Firebase project
2. Enable Cloud Messaging
3. Download configuration files
4. Add them to the project as mentioned in Installation

## 📱 Platform Support

- ✅ Android
- ✅ iOS

## 🌍 Supported Languages

- English (en)
- Arabic (ar) - with RTL support

## 📸 Screenshots

_Add screenshots of your app here_

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Fady Malak**
- GitHub: [@fadymalak1](https://github.com/fadymalak1)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All package maintainers
- Firebase team for backend services

---

Made with Fady Malak using Flutter

"# season_app" 
