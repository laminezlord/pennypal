import 'package:flutter/material.dart';
import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool hide = true;
  bool busy = false;
  String? error;

  @override
  void dispose() { email.dispose(); pass.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || pass.text.isEmpty) {
      setState(() => error = 'Enter your email and password.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { busy = true; error = null; });
    try {
      await PennyPalService.login(email.text, pass.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        pennyPalRoute(const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      // Catch everything: an uncaught Error here left the form idle with no message.
      if (mounted) setState(() => error = e is Exception ? _clean(e.toString()) : PennyPalService.authErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _clean(String value) {
    if (value.contains('wrong-password') || value.contains('invalid-credential')) return 'The email or password is incorrect.';
    if (value.contains('user-not-found')) return 'No PennyPal account was found for this email.';
    return value.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: MotionReveal(delay: const Duration(milliseconds: 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const PennyPalLogo(showWordmark: true, size: 52),
                const SizedBox(height: 52),
                const Text('Welcome back', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: PennyPalTheme.ink)),
                const SizedBox(height: 8),
                const Text('Your money, clearer. Your goals, closer.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 16)),
                const SizedBox(height: 30),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
                const SizedBox(height: 14),
                TextField(controller: pass, obscureText: hide, autofillHints: const [AutofillHints.password], decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(tooltip: hide ? 'Show password' : 'Hide password', onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: PennyPalTheme.danger.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700))),
                ],
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in'))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('Create a PennyPal account'))),
                const SizedBox(height: 22),
                const Text('PennyPal is a student personal-finance learning and expense-management tool. It does not initiate real financial transactions or provide professional financial advice.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 11, height: 1.45)),
              ])),
            ),
          ),
        ),
      ),
    );
  }
}
