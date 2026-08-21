import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'firebase/firebase_service.dart';
import 'providers/app_providers.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/dashboard/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? error;
  try {
    await FirebaseService.initialize();
  } catch (e) {
    error = e;
  }
  runApp(ProviderScope(child: GroupFlowApp(firebaseError: error)));
}

class GroupFlowApp extends ConsumerWidget {
  const GroupFlowApp({super.key, this.firebaseError});
  final Object? firebaseError;
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'GroupFlow',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    home: firebaseError == null
        ? const AuthGate()
        : FirebaseSetupError(error: firebaseError!),
  );
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) => user == null ? const AuthScreen() : const HomeShell(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => FirebaseSetupError(error: e),
    );
  }
}

class FirebaseSetupError extends StatelessWidget {
  const FirebaseSetupError({super.key, required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_suggest_outlined, size: 62),
            const SizedBox(height: 18),
            Text(
              'Firebase setup required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const Text(
              'Add your Firebase configuration with FlutterFire before running GroupFlow. No application data is being simulated.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SelectableText(
              '$error',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
