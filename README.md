# GroupFlow

**Collaborate. Track. Complete.** GroupFlow is a mobile-first Flutter workspace for one student group leader and their members. It keeps coursework tasks, shared notes, files, discussions, and delivery in one private space.

## Implemented MVP foundation

- Firebase email/password authentication, registration profile document, logout, and password reset.
- Firestore-backed groups: unique code, open/request/invite-only join modes, active/removed membership history, leader/member roles, and member removal.
- Leader-created task assignment, member status updates, notifications records, and live task-based progress.
- Shared auto-saving notes with a version record created before changed content is overwritten.
- Firebase Storage file uploads with Firestore metadata, course-file categories, download links, and permission-aware deletion.
- Group discussion posts, stored notification records, GitHub repository data support, and leader-confirmed final submission records.
- Modern mobile shell with Home, Groups, Tasks, Alerts, and Profile navigation, plus loading and empty states.

FCM delivery, task discussion comments, announcement management UI, contribution dashboards, and richer note formatting are the next implementation phase.

## Firebase setup

1. Create a Firebase project and enable Email/Password in **Authentication**.
2. Create Firestore and Firebase Storage.
3. Run `dart pub global activate flutterfire_cli` then `flutterfire configure` in this folder. This creates `lib/firebase_options.dart` and Android/iOS configuration files.
4. Replace the initialization in `lib/firebase/firebase_service.dart` with `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` and import the generated options file.
5. Deploy rules: `firebase deploy --only firestore:rules,storage`.

The app intentionally shows a Firebase setup message until configuration is present; it never supplies fake groups, users, or tasks.

## Run

```bash
flutter pub get
flutter run
```

Detailed project handoff documents are in [docs/](docs/): [Firebase integration](docs/FIREBASE_SETUP.md), [testing](docs/TESTING.md), and [GitHub/build/release](docs/GITHUB_BUILD.md).

## Structure

```
lib/core       theme and shared utilities
lib/models     Firestore domain models
lib/repositories Firebase access and permission-aware operations
lib/providers  Riverpod stream providers
lib/screens    feature-focused presentation screens
lib/widgets    reusable UI components
```

## Security note

Deploy and test the supplied rules before production. Group authorization is enforced in Firestore rules, not merely in the Flutter UI. Review rules alongside every new collection; File Storage should be extended to validate membership through a custom claim or a carefully scoped upload service.

## Next improvements

Firebase Storage metadata and upload UI, discussions/comments, activity timeline, announcements, submission records, notification delivery with FCM, offline banner, rich-text editing, and widget/integration tests.
