import 'package:flutter/material.dart';
import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final first = TextEditingController(); final last = TextEditingController(); final email = TextEditingController(); final phone = TextEditingController(); final pass = TextEditingController();
  bool hide = true; bool busy = false; String? error;
  @override void dispose(){for(final controller in [first,last,email,phone,pass]) controller.dispose(); super.dispose();}
  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() { busy = true; error = null; });
    try {
      await PennyPalService.register({'first_name': first.text, 'last_name': last.text, 'email': email.text, 'mobile_number': phone.text, 'password': pass.text});
    } on Exception catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const PennyPalLogo(showWordmark: true, size: 36)),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 30), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: MotionReveal(delay: const Duration(milliseconds: 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Create your PennyPal', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('A simple place to record, plan, learn and save.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 15)),
        const SizedBox(height: 28),
        Row(children: [Expanded(child: TextField(controller: first, decoration: const InputDecoration(labelText: 'First name'))), const SizedBox(width: 10), Expanded(child: TextField(controller: last, decoration: const InputDecoration(labelText: 'Last name')))]),
        const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
        const SizedBox(height: 12),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: hide, decoration: InputDecoration(labelText: 'Password', helperText: 'At least 8 characters', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
        if (error != null) ...[
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: PennyPalTheme.danger.withOpacity(.08), borderRadius: BorderRadius.circular(12)), child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700))),
        ],
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account'))),
        const SizedBox(height: 12),
        Center(child: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Already have an account? Sign in'))),
        const SizedBox(height: 8),
        const Text('By continuing, you agree that PennyPal is an educational personal-finance tool, not a bank, payment service or professional financial adviser.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 11, height: 1.45)),
      ])))))),
    );
  }
}
