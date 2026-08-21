# GitHub, build, and release procedure

## First-time repository setup

From the GroupFlow project root:

```bash
git init
git add .
git commit -m "chore: initialise GroupFlow Flutter project"
git branch -M main
git remote add origin https://github.com/YOUR-ACCOUNT/groupflow.git
git push -u origin main
```

Create a protected `main` branch on GitHub. Require pull requests and successful checks before merging.

## Branch model

Create the following long-lived branches:

```bash
git checkout -b develop
git push -u origin develop
git checkout main
```

Create feature branches from `develop`:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/auth
# make and test the change
git add lib test docs
git commit -m "feat(auth): add email password flow"
git push -u origin feature/auth
```

Use the requested names: `feature/auth`, `feature/groups`, `feature/tasks`, `feature/workspace`, `feature/files`, `feature/discussion`, `feature/notifications`, and `feature/profile`. Open a pull request into `develop`; merge `develop` into `main` only for a tested release.

## Required checks before a pull request

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Use a real Firebase development project or Emulator Suite for integration checks. Never commit `google-services.json`, `GoogleService-Info.plist`, keystores, service-account JSON, `.env` secrets, or generated build folders.

## Android debug build

```bash
flutter pub get
flutter build apk --debug
```

The APK is generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Install it with Android Debug Bridge if a device is connected:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Android release build

1. Create an upload keystore and store it securely outside the repository.
2. Add a local `android/key.properties` file referencing the keystore. Keep this file ignored by Git.
3. Configure Android signing in the Gradle configuration.
4. Build the signed bundle:

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console (internal testing first). Use Play App Signing for production.

## Suggested GitHub Actions check

Create `.github/workflows/flutter.yml` after the first successful local build. It should check out the repository, install Flutter, run `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test`. Firebase configuration and release signing should be injected as protected GitHub secrets, never checked in.

## Release procedure

1. Merge tested features into `develop`.
2. Complete manual acceptance tests from [TESTING.md](TESTING.md).
3. Merge `develop` into `main` through a reviewed pull request.
4. Update the version in `pubspec.yaml`.
5. Tag and push the release:

```bash
git checkout main
git pull origin main
git tag -a v1.0.0 -m "GroupFlow MVP"
git push origin v1.0.0
```

6. Build the signed Android App Bundle, publish it to internal testing, and verify authentication and Firestore access in the production Firebase project.
