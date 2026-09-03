# Firebase integration guide

## 1. Create the Firebase project

1. Open the Firebase console and create a project named `GroupFlow` (or your chosen production name).
2. Add the Android app using the package ID `com.groupflow.groupflow` unless you intentionally change it in the Flutter project first.
3. Download `google-services.json` and place it at `android/app/google-services.json`.
4. Add iOS only when required, downloading `GoogleService-Info.plist` into `ios/Runner/`.

Do not commit either configuration file to a public repository.

## 2. Enable Firebase products

- Authentication → Sign-in method → enable **Email/Password**.
- Firestore Database → create a database in your chosen region.
- Storage → create the default bucket.
- Cloud Messaging → configure later for delivery; notification records already have a Firestore data model.

## 3. Generate Flutter configuration

Install the FlutterFire CLI once:

```bash
dart pub global activate flutterfire_cli
```

At the project root run:

```bash
flutterfire configure
```

This generates `lib/firebase_options.dart`. Then update `lib/firebase/firebase_service.dart` to initialize with the generated platform options:

```dart
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

abstract final class FirebaseService {
  static Future<void> initialize() => Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

## 4. Install packages and run

```bash
flutter pub get
flutter analyze
flutter run
```

If package download is blocked by a network proxy, configure the proxy or run the command on a network that can reach `pub.dev`. Do not replace Firebase dependencies with mock implementations.

## 5. Deploy rules and indexes

Install and authenticate the Firebase CLI:

```bash
npm install -g firebase-tools
firebase login
firebase init firestore storage
```

When prompted, select the existing project and retain the project files `firestore.rules` and `storage.rules`. Then deploy:

```bash
firebase use groupflow-dd0d4
firebase deploy --only firestore:rules,firestore:indexes,storage
```

The create-group flow is an atomic batch. It writes `groups`, `groupMembers`,
`groupJoinCodes`, `projects`, and `activityLogs` together. The rules use
`getAfter()` to authorize the leader membership and the related records after
that batch is applied. Group creation is currently restricted to the verified
Firebase Authentication email `mugalu2026@gmail.com`; other registered users
can still join groups according to the join settings. Deploy these rules to the
active Firebase project before testing; editing the local file alone does not
change Firebase.

Review rules using the Firebase Rules Playground before deploying production.
The provided storage rule is deliberately a safe starting point and must be
tightened to check group membership before file-upload work is added.

## 6. Required Firestore indexes

The current queries need composite indexes for:

- `groupMembers`: `userId` ascending, `status` ascending
- `groupMembers`: `groupId` ascending, `status` ascending

Firestore reports a direct console link when a missing index is encountered. Create the index through that link and wait for it to finish building.

## 7. Production checklist

- Use separate Firebase projects for development, staging, and production.
- Restrict the API key in Google Cloud where applicable.
- Test rules with non-leader, leader, removed, and unauthenticated accounts.
- Verify group creation as a signed-in user after deploying the current rules;
  the expected result is one active leader membership and one initial project.
- Enable App Check before production use.
- Set up Firestore/Storage budgets and alerts.
- Add a Cloud Function or trusted backend for FCM, deadline reminders, and any privileged aggregation.
