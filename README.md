# Tabz 📱💰

A collaborative expense splitter that reads your receipts and divides the bill your way — equally, by item, or by percentage.

## 🚀 Try It Out

- **🌐 Live Web App:** [tabz-expense-splitter.web.app](https://tabz-expense-splitter.web.app/)

## 🏆 About This Project

Tabz simplifies group expense tracking and settlement. Whether you're splitting rent with roommates, sharing a vacation budget, or tracking group outings, Tabz makes it effortless to:
- **Capture receipts** using OCR (Optical Character Recognition)
- **Split expenses** using multiple strategies
- **Manage groups** and invite friends
- **Track balances** and settle debts
- **Get notifications** about expense updates

## ✨ Key Features

- **AI-Powered Receipt Recognition** - Automatically extract items and amounts from receipt photos using Google ML Kit Text Recognition and Generative AI
- **Flexible Splitting Options** - Split expenses equally, by item, or by custom amount or percentage
- **Group Management** - Create groups, add members, and track shared expenses
- **Real-time Sync** - All data synced with Firebase Firestore for real-time updates across devices
- **User Authentication** - Secure login with Google Sign-In Option
- **Dark/Light Mode** - Persistent theme preferences with light and dark mode support
- **Notifications** - Get updates when expenses are added or settled
- **Activity History** - Track all group activities and transactions
- **Settlement Tracking** - Simplified debt calculation and settlement

## 🛠️ Technical Highlights

This project showcases:
- **AI/ML Integration** - Leveraging Google ML Kit and Generative AI for intelligent receipt processing
- **Real-time Architecture** - Firebase Firestore for instant data synchronization across devices
- **State Management** - Clean Provider pattern implementation for scalable state management
- **Multi-platform Support** - Single Flutter codebase for Android, iOS, Web, Windows, macOS, and Linux
- **Authentication** - Secure OAuth 2.0 implementation with Google Sign-In
- **Persistent Storage** - Local preferences management with SharedPreferences
- **Best Practices** - Modular architecture, separation of concerns, and reactive programming patterns
- **UI/UX** - Material Design 3 compliance with dark/light mode support and smooth animations

### Tech Stack

**Frontend:**
- Flutter (UI Framework)
- Provider (State Management)

**Backend & Services:**
- Firebase Authentication
- Firebase Cloud Firestore (Database)
- Google ML Kit Text Recognition (OCR)
- Google Generative AI (AI-powered receipt analysis)

**Local Storage:**
- Shared Preferences (User preferences, theme settings)

## 📦 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration
├── screens/                  # UI screens
│   ├── splash_screen.dart    # App startup splash screen
│   ├── app_shell.dart        # Main navigation shell
│   ├── home_screen.dart      # Home screen (dashboard)
│   ├── auth/                 # Authentication screens
│   ├── expenses/             # Expense-related screens
│   ├── groups/               # Group management screens
│   ├── friends/              # Friends management
│   ├── profile/              # User profile
│   ├── settings/             # App settings
│   ├── activity/             # Activity history
│   └── notification/         # Notifications
├── core/
│   ├── models/               # Data models
│   ├── providers/            # State management (Provider pattern)
│   ├── services/             # Business logic & external services
│   ├── theme/                # Theme configuration
│   └── widgets/              # Reusable widgets
└── assets/                   # Images and assets
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.44.0)
- Dart SDK (3.12.0)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/chhpyn/tabz.git
   cd tabz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   - Create a `.env` file in the root directory with your Firebase configuration and API keys
   ```
   GEMINI_API_KEY=your_gemini_key_here
   ```

4. **Configure Firebase**
   - Download `google-services.json` for Android
   - Place `google-services.json` in `android/app/`

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 How to Use

### Create or Join a Group
1. Tap the "Create Group" button or "Join Group" if you have an invite
2. Add group members by searching for their email
3. Start splitting expenses

### Add an Expense
1. Navigate to a group and tap "Add Expense"
2. Either:
   - **Capture Receipt** - Take a photo of your receipt; Tabz will automatically extract items and amounts
   - **Manual Entry** - Enter expense details manually
3. Select how to split the expense:
   - **Equally** - Split among all members
   - **By Item** - Assign specific items to members
   - **By Percentage** - Custom percentage distribution
4. Confirm and save

### View and Settle Expenses
1. Check your balance in each group on the Home Screen
2. View transaction history in the Activity section
3. Mark expenses as settled when paid

### Customize Your Experience
1. Go to Settings to toggle Dark/Light mode
2. Your theme preference is automatically saved

## 🔐 Security & Privacy

- All user data is encrypted and stored securely in Firebase
- Google Sign-In ensures secure authentication
- OCR processing is done locally on your device
- Permission requests for camera and gallery access

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is private. All rights reserved.

