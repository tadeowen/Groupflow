# GroupFlow testing guide

This guide covers the implemented Firebase-backed foundation: authentication, groups, memberships, tasks, live progress, and shared notes.

## Before testing

1. Complete the Firebase setup in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).
2. Create two real test accounts (for example, `leader@example.com` and `member@example.com`).
3. Start the Android emulator or connect a physical Android device.
4. From the project root, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Use the Firebase Emulator Suite for repeatable automated tests when it is available. Never use real student data in development tests.

## Manual acceptance tests

| Area | Procedure | Expected result |
| --- | --- | --- |
| Registration | Register with a new email, valid password, and full name. | Firebase Auth account exists and `users/{uid}` is created. |
| Registration validation | Try empty required fields, invalid email, and a password below eight characters. | The screen displays helpful validation messages and no account is created. |
| Login/logout | Log in, then log out from Profile. | Auth state persists during use and logout returns to Login. |
| Password reset | Enter an email and select **Forgot password?**. | Firebase sends a password-reset email. |
| Create group | Log in as the leader and create an open group. | A `groups` record, active leader `groupMembers` record, and activity entry are written. A group code is displayed. |
| Join open group | Log in as the second user and join with the code. | An active member record is created immediately. |
| Join request group | Create a request-only group, then join as the second user. | A pending `joinRequests` record is created; no active membership is created. |
| Group limits | Join until the maximum is reached, then try another account. | The final join is rejected with a friendly “group is full” message. |
| Remove member | Log in as leader and remove the second user. | Membership becomes `removed`, preserving its document and historical attribution. The member loses access after synchronisation. |
| Create task | As leader, create and assign a task. | A task document and notification record are created. |
| Update task | As assignee, change task status to In progress then Completed. | Task status updates; completion timestamp is set for Completed. |
| Progress | Complete several group tasks. | Group overview progress equals completed tasks ÷ total tasks × 100. |
| Notes | Create and edit a note, wait for auto-save, then edit again. | Note persists in `notes`; a previous-content record appears in `noteVersions` after a changed save. |
| Permissions | As a normal member, attempt leader-only actions by using the UI and Firestore console/emulator. | The UI hides leader actions and Firestore rules reject direct unauthorized writes. |

## Security rule test cases

Run these using the Firebase Emulator Suite or a separate Firebase test project:

1. An unauthenticated user cannot read a group, task, note, or membership record.
2. An active member can read only their group’s workspace data.
3. A member cannot update group settings or another member’s membership status.
4. A member cannot create tasks (only a leader can).
5. A task assignee can change their own task status; an unrelated member cannot.
6. A removed member cannot read group data after the status changes to `removed`.

## Current test coverage status

Automated widget and repository tests should be added before release. The app currently includes the manual functional path and Firestore rule definitions; it does not claim test coverage for future modules such as files, discussion, final submissions, or FCM.

## Defect report template

```text
Title:
Build/version:
Device and Android version:
Firebase environment (emulator/dev/staging):
Steps to reproduce:
Expected result:
Actual result:
Screenshot/logs:
```
