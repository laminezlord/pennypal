import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';
import '../assistant/assistant_screen.dart';
import '../admin_screen.dart';
import '../budget/budget_screen.dart';
import '../learning/learning_screen.dart';
import '../profile/profile_screen.dart';
import '../savings/savings_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  bool isAdmin = false;
  List<Widget> get _screens => [
    DashboardView(data: dash, loading: loading, onRefresh: _loadDashboard, onNavigate: _nav),
    const TransactionsScreen(),
    const BudgetScreen(),
    const SavingsScreen(),
    isAdmin ? const AdminScreen() : const LearningScreen(),
  ];
  Map<String, dynamic> dash = PennyPalService.emptyDashboard();
  bool loading = false;
  bool _dashboardBusy = false;

  @override
  void initState() {
    super.initState();
    // Load immediately when the dashboard is first mounted. Previously this
    // was only reached after a manual refresh, leaving the summary tiles in a
    // loading state until the user pulled to refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboard();
        _loadRole();
      }
    });
  }

  Future<void> _loadRole() async {
    try {
      final role = await PennyPalService.role();
      if (mounted) setState(() => isAdmin = role == 'admin');
    } catch (_) {
      if (mounted) setState(() => isAdmin = false);
    }
  }

  Future<void> _loadDashboard() async {
    if (_dashboardBusy) return;
    _dashboardBusy = true;
    try {
      // Render the dashboard from cache/local state first. Never make the
      // first frame wait for a sync or notification operation.
      final d = await PennyPalService.dashboard().timeout(
        const Duration(seconds: 3),
        onTimeout: () => PennyPalService.emptyDashboard(),
      );
      if (mounted) {
        setState(() {
          dash = d;
          loading = false;
        });
      }
      // Sync in the background and refresh once it finishes.
      final synced = await PennyPalService.syncPendingTransactions().timeout(const Duration(seconds: 1), onTimeout: () => 0);
      if (synced > 0 && mounted) {
        final fresh = await PennyPalService.dashboard().timeout(const Duration(seconds: 2), onTimeout: () => dash);
        if (mounted) setState(() => dash = fresh);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    } finally {
      _dashboardBusy = false;
    }
  }

  void _nav(int i) {
    if (i == tab) return;
    setState(() => tab = i);
  }


  Future<void> _openQuickAdd(BuildContext context, {bool income = false}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => QuickAddSheet(income: income),
    );
    if (!mounted || result == null) return;

    await _loadDashboard();
    if (!mounted) return;
    final message = result['message'] as String?;
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep the tab pages mounted instead of reparenting them through a
      // PageView. This is more stable on Android tablets, especially while
      // Firestore/auth state is changing during offline/online transitions.
      // The bottom navigation intentionally changes tabs without a transition.
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: _nav,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Overview'),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Activity'),
          const NavigationDestination(icon: Icon(Icons.track_changes_outlined), selectedIcon: Icon(Icons.track_changes), label: 'Budget'),
          const NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(
            icon: Icon(isAdmin ? Icons.admin_panel_settings_outlined : Icons.school_outlined),
            selectedIcon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.school),
            label: isAdmin ? 'Admin' : 'Learn',
          ),
        ],
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton.small(
              heroTag: 'dashboard-add',
              backgroundColor: PennyPalTheme.navy,
              foregroundColor: Colors.white,
              elevation: 6,
              tooltip: 'Add transaction',
              onPressed: () => _openQuickAdd(context),
              child: const Icon(Icons.add_rounded, size: 24),
            )
          : null,
    );
  }
}

class DashboardView extends StatelessWidget {
  final Map<String, dynamic>? data; final bool loading; final Future<void> Function() onRefresh; final ValueChanged<int> onNavigate;
  const DashboardView({super.key, required this.data, required this.loading, required this.onRefresh, required this.onNavigate});
  @override Widget build(BuildContext context) {
    final d = data ?? {};
    final user = PennyPalService.currentUser;
    final name = (user?.displayName ?? 'there').split(' ').first;
    final balance = d['balance'] as num? ?? 0;
    final income = d['income'] as num? ?? 0;
    final expenses = d['expenses'] as num? ?? 0;
    final budget = d['budget_total'] as num? ?? 0;
    final monthExpenses = d['month_expenses'] as num? ?? 0;
    final percent = d['budget_percent'] as num? ?? 0;
    final recentRaw = d['recent_transactions'];
    final recent = recentRaw is List ? recentRaw : const <dynamic>[];
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final horizontal = wide ? 32.0 : 18.0;
        final content = ListView(padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 110), children: [
          MotionReveal(delay: const Duration(milliseconds: 40), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Good ${DateTime.now().hour < 12 ? 'morning' : DateTime.now().hour < 18 ? 'afternoon' : 'evening'}, $name', style: const TextStyle(color: PennyPalTheme.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              const Text('Your financial overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: PennyPalTheme.ink)),
            ])),
            IconButton.filledTonal(onPressed: () => Navigator.of(context).push(pennyPalRoute(const AssistantScreen())), icon: const Icon(Icons.auto_awesome)),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: () => Navigator.of(context).push(pennyPalRoute(const ProfileScreen())), icon: const Icon(Icons.person_outline)),
          ])),
          const SizedBox(height: 20),
          MotionReveal(delay: const Duration(milliseconds: 110), child: GradientHeader(eyebrow: 'AVAILABLE BALANCE', title: money(balance), subtitle: balance >= 0 ? 'Keep your spending aligned with your goals.' : 'Your recorded expenses are above income.', trailing: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28)))),
          const SizedBox(height: 14),
          if ((d['pending_sync_count'] as num? ?? 0) > 0) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Expanded(child: Text('${d['pending_sync_count']} expense(s) waiting to sync. They are saved on this device and will upload automatically when internet returns.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          MotionReveal(delay: const Duration(milliseconds: 180), child: loading ? const LoadingCard() : LayoutBuilder(builder: (context, c) {
            final two = c.maxWidth >= 600;
            final children = [StatTile(label: 'Total income', value: income, icon: Icons.south_west_rounded, accent: PennyPalTheme.mint, showMoney: true), StatTile(label: 'Total expenses', value: expenses, icon: Icons.north_east_rounded, accent: PennyPalTheme.sky, showMoney: true)];
            return two ? Row(children: [Expanded(child: children[0]), const SizedBox(width: 12), Expanded(child: children[1])]) : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [children[0], const SizedBox(height: 12), children[1]]);
          })),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('This month', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), TextButton(onPressed: () => onNavigate(2), child: const Text('View budget'))]),
          MotionReveal(delay: const Duration(milliseconds: 250), child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: PennyPalTheme.sky.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.pie_chart_outline, color: PennyPalTheme.sky)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Budget usage', style: TextStyle(fontWeight: FontWeight.w900)), Text(budget > 0 ? 'Based on your monthly limit' : 'Set a monthly limit to track progress', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12))])), Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: budget <= 0 ? 0 : (monthExpenses / budget).clamp(0, 1).toDouble()), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic, builder: (context, value, _) => LinearProgressIndicator(minHeight: 10, value: value))),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Spent ${money(monthExpenses)}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)), Text(budget > 0 ? 'Left ${money((budget - monthExpenses).clamp(0, double.infinity))}' : 'No limit yet', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, fontWeight: FontWeight.w700))]),
          ]))),
          const SizedBox(height: 22),
          const SectionTitle('Quick actions'), const SizedBox(height: 10),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: wide ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: wide ? 2.2 : 1.7, children: [
            _ActionTile('Add expense', Icons.remove_circle_outline, PennyPalTheme.sky, () => _openQuickAddFromDashboard(context, onRefresh)),
            _ActionTile('Add income', Icons.add_circle_outline, PennyPalTheme.mint, () => _openQuickAddFromDashboard(context, onRefresh, income: true)),
            _ActionTile('Ask PennyPal', Icons.auto_awesome, PennyPalTheme.navy, () => Navigator.of(context).push(pennyPalRoute(const AssistantScreen()))),
            _ActionTile('My goals', Icons.flag_outlined, PennyPalTheme.amber, () => onNavigate(3)),
          ]),
          const SizedBox(height: 22),
          SectionTitle('Recent activity', action: 'See all', onTap: () => onNavigate(1)), const SizedBox(height: 10),
          if (recent.isEmpty) const EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet', message: 'Add your first income or expense and PennyPal will start building your picture.')
          else AppCard(padding: EdgeInsets.zero, child: Column(children: recent.take(5).map((x) => _RecentRow(x)).toList())),
        ]);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: content,
          ),
        );
      }),
    );
  }
}

class _RecentRow extends StatelessWidget { final dynamic x; const _RecentRow(this.x); @override Widget build(BuildContext context) { final income = x['type'] == 'INCOME'; final amount = num.tryParse('${x['amount']}') ?? 0; return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: (income ? PennyPalTheme.mint : PennyPalTheme.sky).withValues(alpha: .10), borderRadius: BorderRadius.circular(13)), child: Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded, color: income ? PennyPalTheme.mint : PennyPalTheme.sky)), title: Text('${x['description']}'.isEmpty ? 'Untitled transaction' : '${x['description']}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${x['category_detail']?['name'] ?? 'Miscellaneous'} • ${x['date'] ?? ''}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)), trailing: Text('${income ? '+' : '-'}${money(amount)}', style: TextStyle(fontWeight: FontWeight.w900, color: income ? PennyPalTheme.mint : PennyPalTheme.danger))); } }

class _ActionTile extends StatelessWidget { final String title; final IconData icon; final Color color; final VoidCallback onTap; const _ActionTile(this.title, this.icon, this.color, this.onTap); @override Widget build(BuildContext context) => MotionPress(onTap: onTap, child: AppCard(padding: const EdgeInsets.all(15), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)))]))); }

Future<void> _openQuickAddFromDashboard(
  BuildContext context,
  Future<void> Function() onRefresh, {
  bool income = false,
}) async {
  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => QuickAddSheet(income: income),
  );
  if (!context.mounted || result == null) return;

  try {
    await onRefresh().timeout(const Duration(seconds: 3));
  } catch (_) {}

  if (!context.mounted) return;
  final message = result['message'] as String?;
  if (message != null && message.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }
}

class QuickAddSheet extends StatefulWidget {
  final bool income;
  const QuickAddSheet({super.key, this.income = false});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final amount = TextEditingController();
  final desc = TextEditingController();
  String category = 'Food';
  DateTime date = DateTime.now();
  bool busy = false;
  XFile? receipt;

  @override
  void dispose() {
    amount.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }

    if (busy) return;
    setState(() => busy = true);

    try {
      String? receiptUrl;
      bool receiptPending = false;
      if (receipt != null && await PennyPalService.hasNetwork()) {
        try {
          receiptUrl = await PennyPalService.uploadReceipt(receipt!)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          receiptPending = true;
        }
      } else if (receipt != null) {
        receiptPending = true;
      }

      final saved = await PennyPalService.addTransaction({
        'type': widget.income ? 'INCOME' : 'EXPENSE',
        'amount': value,
        'category_name': category,
        'description': desc.text.trim(),
        'date': date.toIso8601String().substring(0, 10),
        'payment_mode': 'Cash',
        'receipt_image_url': receiptUrl,
      });

      final alert = saved['budget_alert'] as String?;
      final message = receiptPending
          ? 'Transaction saved. Receipt upload is waiting for internet.'
          : alert;

      if (!mounted) return;
      // The result is handed to the parent before this route is popped. No
      // setState, inherited-widget lookup, or snackbar is performed afterward.
      setState(() => busy = false);
      Navigator.of(context).pop(<String, dynamic>{
        'message': message,
        'pendingSync': saved['pending_sync'] == true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $e')),
      );
    }
  }

  Future<void> pickReceipt() async {
    if (busy) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => receipt = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the camera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.income ? 'Add income' : 'Add expense',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                widget.income
                    ? 'Record money you received.'
                    : 'Capture a purchase while you remember it.',
                style: const TextStyle(color: PennyPalTheme.muted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: amount,
                enabled: !busy,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦ '),
              ),
              const SizedBox(height: 12),
              if (!widget.income)
                DropdownButtonFormField<String>(
                  value: category,
                  items: PennyPalService.categories
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => category = v ?? category),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              if (!widget.income) const SizedBox(height: 12),
              TextField(
                controller: desc,
                enabled: !busy,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.income ? 'Source / description' : 'Description',
                  hintText: widget.income ? 'Allowance, salary...' : 'What did you spend on?',
                ),
              ),
              if (!widget.income) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : pickReceipt,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(receipt == null ? 'Attach receipt photo (optional)' : 'Receipt attached'),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : save,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
