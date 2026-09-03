# GroupFlow

**Collaborate. Track. Complete.** GroupFlow is a mobile-first Flutter workspace for one student group leader and their members. It keeps coursework tasks, shared notes, files, discussions, and delivery in one private space.

## Implemented MVP

- Firebase email/password authentication, registration profile document, logout, and password reset.
- Firestore-backed groups: unique code, open/request/invite-only join modes, active/removed membership history, leader/member roles, and member removal.
- Coursework/project entity: each group has one or more coursework projects, each with its own deadline and status (active/completed/archived).
- Leader-created task assignment, member status updates, notifications records, and live project-based progress.
- Shared auto-saving notes with a version record created before changed content is overwritten, plus a version history viewer.
- Firebase Storage file uploads with Firestore metadata, course-file categories, download links, uploader attribution, and permission-aware deletion.
- Group discussion posts with per-post comments, join-request approval/rejection for leaders, announcements, and an activity timeline.
- Group settings: name, description, coursework title, maximum members, join mode, deadline, GitHub repository link, and group locking.
- Final coursework submission with status history (DRAFT, SUBMITTED, RESUBMITTED), confirmation dialog, and timestamp tracking.
- Modern mobile shell with Home, Groups, Tasks, Alerts, and Profile navigation, plus loading and empty states.
- User-friendly error messages for common Firebase errors (auth, permission-denied, network, etc.).
- Profile editing (name, student number) and password reset from the profile screen.

FCM push notifications, rich-text note formatting, and widget/integration tests are the next implementation phase.

## Firebase setup

1. Create a Firebase project and enable Email/Password in **Authentication**.
2. Create Firestore and Firebase Storage.
3. Run `dart pub global activate flutterfire_cli` then `flutterfire configure` in this folder. This creates `lib/firebase_options.dart` and Android/iOS configuration files.
4. Replace the initialization in `lib/firebase/firebase_service.dart` with `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` and import the generated options file.
5. Deploy the rules and indexes to the same Firebase project used by `lib/firebase_options.dart`:

   ```bash
   firebase use groupflow-dd0d4
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

   Group creation is one atomic batch: the group, leader membership, join code,
   first project, and activity entry must all be authorized by the deployed
   rules. If the app still reports a permission error after a code change, the
   deployed rules are stale; deploy them before testing again.

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

Deploy and test the supplied rules before production. Group authorization is enforced in Firestore rules, not merely in the Flutter UI. A signed-in user can create a group and becomes its leader in the same atomic operation; leaders can manage membership, projects, settings, announcements, and submissions, while active members can collaborate in workspace notes, files, discussions, and comments. Review rules alongside every new collection; File Storage should be extended to validate membership through a custom claim or a carefully scoped upload service.

## Next improvements

Offline persistence indicator, rich-text editing, FCM push delivery, widget and integration tests.
