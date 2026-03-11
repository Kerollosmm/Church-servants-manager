# Setup Guide

## Prerequisites

| Tool | Minimum Version | Notes |
|---|---|---|
| Flutter SDK | 3.x | Dart ≥ 3.9.2 bundled |
| Dart SDK | 3.9.2 | Bundled with Flutter |
| Android Studio / Xcode | Latest stable | For device/emulator targets |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| FlutterFire CLI | Latest | `dart pub global activate flutterfire_cli` |
| Node.js | 18+ | Required only for Cloud Functions |

Verify your Flutter installation:

```bash
flutter doctor
```

All items in `flutter doctor` should pass for your target platform(s).

---

## 1. Clone the Repository

```bash
git clone <repository-url>
cd church_managment_system
```

---

## 2. Firebase Project Setup

### Option A — Use an existing Firebase project

1. Log in: `firebase login`
2. Link the project: `firebase use <your-project-id>`
3. Regenerate `firebase_options.dart`:
   ```bash
   flutterfire configure --project=<your-project-id>
   ```

### Option B — Create a new Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a project.
2. Enable **Authentication** (Email/Password provider).
3. Enable **Firestore** in production mode.
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`.

---

## 3. Deploy Firestore Rules and Indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

The rules in `firestore.rules` are mandatory — without them all client reads/writes will be rejected.

---

## 4. Install Dart Dependencies

```bash
flutter pub get
```

---

## 5. Run Code Generation

The project uses `freezed`, `json_serializable`, and `hive_generator`. Generated files are already committed, but regenerate after any model change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 6. Configure Platform Targets

### Android

1. Place `google-services.json` (downloaded from Firebase Console → Project Settings → Android app) in `android/app/`.
2. Set minimum SDK ≥ 21 in `android/app/build.gradle`.
3. Configure NDK version if required (see `android/app/build.gradle`).

### iOS

1. Place `GoogleService-Info.plist` in `ios/Runner/`.
2. Open `ios/Runner.xcworkspace` in Xcode, set your Bundle ID, and enable the required capabilities (Push Notifications if needed).

### Web / Desktop

The app compiles for web and desktop but Firebase configuration and feature completeness may vary. Run `flutterfire configure` including the web platform to generate the correct options.

---

## 7. Run the Application

```bash
# Run on a connected device or emulator
flutter run

# Specify a device
flutter run -d <device-id>

# List available devices
flutter devices
```

---

## 8. Create the First Admin Account

Firebase Authentication does not have a bootstrap admin concept. The recommended flow:

1. Register a new account through the app (default role: `student`).
2. In the Firebase Console (or using the Firebase Admin SDK), open the `Users` Firestore collection and manually set `role` to `'admin'` for that document.
3. The user should sign out and sign back in to reload their profile.

From then on, the admin user can provision other admin and servant accounts through the in-app admin panel.

---

## 9. Deploy Cloud Functions (Optional)

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Cloud Functions handle server-side administrative operations (account provisioning, etc.).

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `firebase_options.dart` missing | Run `flutterfire configure` |
| Build fails with NDK error | Set `ndkVersion` in `android/app/build.gradle`; download via Android Studio SDK Manager |
| Firestore access denied | Ensure rules are deployed; check user is not archived |
| `build_runner` conflicts | Run with `--delete-conflicting-outputs` |
| Code-gen loop | Delete `.dart_tool/build/` and re-run `build_runner build` |
