import 'package:flutter/material.dart';

import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';
import '../admin_screen.dart';
import '../reports_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<String> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = PennyPalService.role();
  }

  @override
  Widget build(BuildContext context) {
    final user = PennyPalService.currentUser;
    final initial = (user?.displayName ?? 'P').trim().isEmpty ? 'P' : (user?.displayName ?? 'P').trim()[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          MotionReveal(delay: const Duration(milliseconds: 40), child: AppCard(
            child: Row(children: [
              Container(width: 58, height: 58, decoration: const BoxDecoration(color: Color(0xFF0B1F3A), shape: BoxShape.circle), child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FutureBuilder<String>(
                  future: _roleFuture,
                  builder: (context, snapshot) {
                    final isAdmin = snapshot.data == 'admin';
                    return Text(
                      isAdmin ? 'PennyPal Admin' : (user?.displayName ?? 'PennyPal student'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(child: Text(user?.email ?? '', style: const TextStyle(color: Color(0xFF66758A), fontSize: 12))),
                    FutureBuilder<String>(
                      future: _roleFuture,
                      builder: (context, snapshot) => snapshot.data == 'admin'
                          ? Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: PennyPalTheme.sky.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: const Text('ADMIN', style: TextStyle(color: PennyPalTheme.sky, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .7)))
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ])),
            ]),
          )),
          const SizedBox(height: 14),
          MotionReveal(delay: const Duration(milliseconds: 120), child: _Section(children: [
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Reports & spending trends'),
              subtitle: const Text('See category and monthly patterns'),
              onTap: () => Navigator.of(context).push(pennyPalRoute(const ReportsScreen())),
            ),

          ])),
          const SizedBox(height: 14),
          MotionReveal(delay: const Duration(milliseconds: 220), child: _Section(children: [
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('About PennyPal'), onTap: () => _about(context)),
            ListTile(leading: const Icon(Icons.rate_review_outlined), title: const Text('Send feedback'), subtitle: const Text('Rate your experience and leave a comment'), onTap: () => _feedback(context)),
            ListTile(leading: const Icon(Icons.support_agent), title: const Text('Contact support'), onTap: () => _support(context)),
          ])),
          FutureBuilder<String>(
            future: _roleFuture,
            builder: (context, snapshot) {
              if (snapshot.data != 'admin') return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AdminFooterCard(context),
              );
            },
          ),
          const SizedBox(height: 0),
          _Section(children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFE85D75)),
              title: const Text('Log out', style: TextStyle(color: Color(0xFFE85D75), fontWeight: FontWeight.w800)),
              onTap: () async {
                await PennyPalService.logout();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
            ),
          ]),
          const SizedBox(height: 18),
          const Center(child: Text('PennyPal • Student finance learning & expense management', style: TextStyle(color: Color(0xFF66758A), fontSize: 11))),
        ],
      ),
    );
  }

  Widget _AdminFooterCard(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: PennyPalTheme.navy.withValues(alpha: .08), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.admin_panel_settings_outlined, color: PennyPalTheme.navy),
          ),
          title: const Text('Admin centre', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: const Text('Users, support and learning content'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(pennyPalRoute(const AdminScreen())),
        ),
      );

  Future<void> _about(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const PennyPalLogo(showWordmark: true, size: 40),
          content: const Text(
            'PennyPal helps students record everyday money activity, plan budgets, track savings goals and learn practical personal-finance concepts. It is not a bank, wallet, payment service or professional financial adviser.',
            style: TextStyle(height: 1.45),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Close'))],
        ),
      );

  Future<void> _feedback(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  Future<void> _support(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SupportScreen()),
    );
  }

}


class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController comments;
  int rating = 5;
  bool sending = false;
  bool submitted = false;
  String? error;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: PennyPalService.currentUser?.displayName ?? '');
    email = TextEditingController(text: PennyPalService.currentUser?.email ?? '');
    comments = TextEditingController();
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    comments.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || comments.text.trim().isEmpty) {
      setState(() => error = 'Please complete your name, email and comments.');
      return;
    }
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await PennyPalService.feedback(name.text, email.text, rating, comments.text);
      if (!mounted) return;
      setState(() {
        sending = false;
        submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sending = false;
        error = 'Could not submit feedback. Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share feedback', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: submitted ? _successCard(context) : _formCard(context),
          ),
        ),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rate_review_outlined, size: 42, color: PennyPalTheme.sky),
          const SizedBox(height: 14),
          const Text('How was your PennyPal experience?', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          const Text('Your feedback helps us improve the app for students.', style: TextStyle(color: PennyPalTheme.muted, height: 1.45)),
          const SizedBox(height: 24),
          const Text('Your rating', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(5, (i) {
                final selected = i < rating;
                return IconButton(
                  tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
                  onPressed: sending ? null : () => setState(() => rating = i + 1),
                  iconSize: 42,
                  icon: Icon(selected ? Icons.star_rounded : Icons.star_border_rounded, color: selected ? PennyPalTheme.amber : PennyPalTheme.line),
                );
              }),
            ),
          ),
          Center(child: Text('$rating out of 5', style: const TextStyle(color: PennyPalTheme.muted, fontWeight: FontWeight.w700))),
          const SizedBox(height: 22),
          TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 14),
          TextField(controller: comments, minLines: 5, maxLines: 8, textInputAction: TextInputAction.newline, decoration: const InputDecoration(labelText: 'Tell us what you think', hintText: 'What did you like? What should we improve?')),
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: PennyPalTheme.danger.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700))),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: sending ? null : submit,
              icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              label: Text(sending ? 'Submitting…' : 'Submit feedback'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(34),
      child: Column(
        children: [
          Container(width: 74, height: 74, decoration: BoxDecoration(color: PennyPalTheme.mint.withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 42, color: PennyPalTheme.mint)),
          const SizedBox(height: 20),
          const Text('Thank you!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Your feedback has been submitted successfully.', textAlign: TextAlign.center, style: TextStyle(color: PennyPalTheme.muted, height: 1.45)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))),
        ],
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final subject = TextEditingController();
  final message = TextEditingController();
  bool sending = false;
  bool submitted = false;
  String? error;

  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (subject.text.trim().isEmpty || message.text.trim().isEmpty) {
      setState(() => error = 'Please complete the subject and message.');
      return;
    }
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await PennyPalService.support(subject.text, message.text);
      if (!mounted) return;
      setState(() {
        sending = false;
        submitted = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        sending = false;
        error = 'Could not send the support request. Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact support', style: TextStyle(fontWeight: FontWeight.w900))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: submitted ? _successCard(context) : _formCard(),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return AppCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.support_agent_rounded, size: 44, color: PennyPalTheme.sky),
          const SizedBox(height: 14),
          const Text('How can we help?', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          const Text('Tell us what you need help with and our support team can review your request.', style: TextStyle(color: PennyPalTheme.muted, height: 1.45)),
          const SizedBox(height: 24),
          TextField(controller: subject, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.subject_rounded))),
          const SizedBox(height: 14),
          TextField(controller: message, minLines: 7, maxLines: 12, textInputAction: TextInputAction.newline, decoration: const InputDecoration(labelText: 'Describe your issue', hintText: 'Include any details that will help us understand the problem.')),
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: PennyPalTheme.danger.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700))),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: sending ? null : submit, icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded), label: Text(sending ? 'Sending…' : 'Send support request'))),
        ],
      ),
    );
  }

  Widget _successCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(34),
      child: Column(
        children: [
          Container(width: 74, height: 74, decoration: BoxDecoration(color: PennyPalTheme.mint.withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 42, color: PennyPalTheme.mint)),
          const SizedBox(height: 20),
          const Text('Request sent', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Your support request has been submitted successfully.', textAlign: TextAlign.center, style: TextStyle(color: PennyPalTheme.muted, height: 1.45)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});
  @override
  Widget build(BuildContext context) => AppCard(padding: EdgeInsets.zero, child: Column(children: children));
}
