# hack_social

A social app built for the [Waveful](https://waveful.com) hackathon using Flutter.

## About

This is a social media application developed as part of the Waveful hackathon. The app provides a platform for users to share content, create posts, and interact with others.

## Architecture

This project follows a **feature-first architecture** pattern, organizing code by features rather than technical layers. This approach promotes better code organization, scalability, and maintainability.

### Project Structure

```
lib/
├── features/           # Feature modules
│   ├── feed/          # Feed screen and related components
│   ├── studio/        # Studio (create) screen and related components
│   └── profile/       # Profile screen and related components
├── core/              # Shared utilities and configurations
│   ├── constants/     # App-wide constants
│   └── theme/         # Theme configuration
└── main.dart          # App entry point
```

### Features

- **Feed**: Browse and view social content
- **Studio**: Create and share new content
- **Profile**: View and manage user profile

## UI Library

This project uses [LuckyUI](https://pub.dev/packages/luckyui) as the primary UI component library. LuckyUI provides a set of beautiful, customizable Flutter widgets to accelerate development.

### Installation

To install LuckyUI, run:

```bash
flutter pub get luckyui
```

Or add it to your `pubspec.yaml`:

```yaml
dependencies:
  luckyui: ^0.0.3
```

## Getting Started

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Tech Stack

- **Framework**: Flutter
- **UI Library**: LuckyUI
- **Architecture**: Feature-first
- **Language**: Dart
