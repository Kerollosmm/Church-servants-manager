# CSMS - Church Servants Management System

A Flutter-based application designed to streamline the management of church services, servants, and students.

## Project Overview

CSMS provides a centralized platform for:
- **Role-Based Authentication**: Secure access for Admins, Servants, and Students using Firebase Auth.
- **Comprehensive Data Management**: Cloud-synced user profiles, roles, and entities via Firestore.
- **Attendance Tracking**: Full-featured attendance management for various church activities with real-time updates.
- **Team & Group Organization**: Manage servants and students in teams/classes.
- **Real-time Updates**: Instant data synchronization and role/permission management.
- **Offline Support**: Persistent local caching for continued operation during network interruptions.

Built with Flutter and Firebase, following a clean architecture with Bloc/Cubit for state management.

## Key Features

### Authentication & Authorization
- Email/password authentication with Firebase Auth
- Role-based access control (Admin, Servant, Student)
- Email verification workflow
- Password reset functionality
- Session persistence and automatic refresh

### Student Management
- Complete CRUD operations for student records
- Advanced search and filtering capabilities
- Student profile management with detailed information
- Bulk operations and data export
- Attendance history tracking per student

### Servant/Teacher Management
- Servant profile management
- Team assignment and role management
- Qualification and certification tracking
- Availability scheduling
- Performance metrics and reporting

### Attendance System
- Session creation and management with flexible scheduling
- Real-time attendance taking with multiple status options (Present, Late, Absent, Excused)
- Bulk marking capabilities for efficient processing
- Attendance history and analytics
- Conflict detection for overlapping sessions
- Offline-capable with automatic sync when connectivity resumes

### Administrative Features
- Team/class creation and management
- Role and permission administration
- System configuration and settings
- Audit logs and activity tracking
- Data backup and recovery tools

### Technical Architecture
- **Clean Architecture**: Separation of concerns with distinct presentation, domain, and data layers
- **State Management**: Flutter Bloc/Cubit pattern for predictable state transitions
- **Dependency Injection**: GetIt for service location and dependency management
- **Data Persistence**: Firebase Firestore with offline caching
- **Local Storage**: Hive for lightweight local caching when needed
- **Routing**: GoRouter for declarative, type-safe navigation
- **Internationalization**: Arabic language support with RTL layout

## Getting Started

### Prerequisites
- Flutter SDK (3.x or higher)
- Dart SDK (3.x or higher)
- Firebase account and project
- Android Studio / VS Code with Flutter plugins

### Installation
1. Clone the repository
2. Copy `firebase_options.dart.example` to `firebase_options.dart` and fill in your Firebase configuration
3. Run `flutter pub get` to install dependencies
4. Execute `flutterfire configure` to set up Firebase services
5. Run the app with `flutter run`

### Firebase Setup
The project requires the following Firebase services:
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions (for backend operations)
- Firebase Analytics (optional but recommended)

## Project Structure

```
lib/
├── church_app.dart           # App entry point and theme
├── main.dart                 # Application bootstrap
├── role_user_route.dart      # Role-based root navigation
├── core/                     # Shared infrastructure
│   ├── di/                   # Dependency injection
│   ├── routing/              # App navigation
│   ├── theme/                # Design tokens and theming
│   ├── constants/            # App-wide constants and enums
│   ├── utils/                # Utility functions and helpers
│   └── widgets/              # Reusable UI components
└── features/                 # Feature modules (Clean Architecture)
    ├── auth/                 # Authentication feature
    ├── student/              # Student management
    ├── servant/              # Servant/Teacher management
    ├── attendance/           # Attendance tracking system
    ├── team/                 # Team and group management
    └── admin/                # Administrative functions
```

## Development Guidelines

See [GEMINI.md](GEMINI.md) for detailed development guidelines, architecture decisions, and coding standards.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the excellent UI toolkit
- Firebase team for the backend services
- Open source packages used throughout the project
- Contributors and maintainers