# Contacts (Flutter + Supabase)

A modern, real-time messaging and contact management Flutter application powered by **Supabase** (Auth, Database, Realtime subscriptions) and **Flutter Riverpod** state management.

---

## 📱 Features

- **Authentication**: Email/password registration and login with profile initialization.
- **Contact Sync & Directory**: Device contact discovery via `flutter_contacts` and user profiles directory.
- **Real-Time Direct Chat**: Peer-to-peer 1-on-1 chat rooms with deterministic UUID generation and real-time message streaming.
- **State Management**: Reactive state management with `flutter_riverpod`.
- **Modern UI**: Clean Material 3 design with responsive layouts and quick calling/SMS integration.

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.29+ / Dart 3.5+
- **Backend / Database**: Supabase (PostgreSQL, Row Level Security, Auth, Realtime)
- **State Management**: Flutter Riverpod (`flutter_riverpod: ^2.4.9`)
- **Device Integrations**: `flutter_contacts`, `url_launcher`
- **Testing**: `flutter_test` (Unit & Widget testing)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.29.0 or higher recommended)
- A Supabase project with `profiles`, `chat_rooms`, and `messages` tables

### Environment Configuration
Provide your Supabase credentials via compile-time `--dart-define` parameters or use default configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Running Tests & Static Analysis

```bash
# Run static analysis
flutter analyze

# Run unit and widget test suite
flutter test
```
