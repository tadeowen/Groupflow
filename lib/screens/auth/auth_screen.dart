import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      student = TextEditingController();
  bool register = false, loading = false;
  @override
  void dispose() {
    for (final c in [name, email, password, student]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (register) {
        await auth.register(
          fullName: name.text,
          email: email.text,
          password: password.text,
          studentNumber: student.text.isEmpty ? null : student.text,
        );
      } else {
        await auth.signIn(email.text, password.text);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.hub_rounded,
                      size: 64,
                      color: Color(0xFF3347B7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GroupFlow',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      register
                          ? 'Create a shared space for your group.'
                          : 'Collaborate. Track. Complete.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (register) ...[
                      field(name, 'Full name', required: true),
                      const SizedBox(height: 12),
                      field(student, 'Student number (optional)'),
                    ],
                    if (register) const SizedBox(height: 12),
                    field(email, 'Email', emailType: true, required: true),
                    const SizedBox(height: 12),
                    field(password, 'Password', secret: true, required: true),
                    const SizedBox(height: 20),
                    AppButton(
                      label: register ? 'Create account' : 'Login',
                      onPressed: submit,
                      loading: loading,
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .resetPassword(email.text);
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email sent.'),
                              ),
                            );
                        } catch (e) {
                          if (mounted) showError(context, e);
                        }
                      },
                      child: const Text('Forgot password?'),
                    ),
                    const Divider(),
                    TextButton(
                      onPressed: () => setState(() => register = !register),
                      child: Text(
                        register
                            ? 'Already have an account? Login'
                            : 'New to GroupFlow? Create account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool emailType = false,
    bool secret = false,
  }) => TextFormField(
    controller: controller,
    obscureText: secret,
    keyboardType: emailType ? TextInputType.emailAddress : null,
    decoration: InputDecoration(labelText: label),
    validator: (v) {
      if (required && (v == null || v.trim().isEmpty))
        return '$label is required.';
      if (emailType && !v!.contains('@')) return 'Enter a valid email.';
      if (secret && v!.length < 8) return 'Use at least 8 characters.';
      return null;
    },
  );
}
