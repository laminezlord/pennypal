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
import '../reports_screen.dart';
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
    // Only the visible tab gets a non-zero signal, so switching tabs reloads
    // just the page being opened.
    TransactionsScreen(refreshSignal: tab == 1 ? _refreshSignal : 0),
    BudgetScreen(refreshSignal: tab == 2 ? _refreshSignal : 0),
    SavingsScreen(refreshSignal: tab == 3 ? _refreshSignal : 0),
    isAdmin ? const AdminScreen() : LearningScreen(refreshSignal: tab == 4 ? _refreshSignal : 0),
  ];
  Map<String, dynamic> dash = PennyPalService.emptyDashboard();
  bool loading = true;
  bool _dashboardBusy = false;
  // Bumped whenever the user switches tabs. The tab pages stay mounted inside
  // the IndexedStack, so they use this to reload instead of showing data from
  // when they were first opened.
  int _refreshSignal = 0;

  @override
  void initState() {
    super.initState();
    // Load immediately when the dashboard is first mounted. Previously this
    // was only reached after a manual refresh, leaving the summary tiles in a
    // loading state until the user pulled to refresh.
    afterNextFrame((_) {
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
      // On a slow connection keep the figures already on screen rather than
      // flashing zeros that look like lost data.
      final d = await PennyPalService.dashboard().timeout(
        const Duration(seconds: 12),
        onTimeout: () => dash,
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
    setState(() {
      tab = i;
      _refreshSignal++;
    });
    if (i == 0) _loadDashboard();
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
      afterNextFrame((_) {
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
          if (!loading && income == 0 && expenses == 0 && budget == 0) ...[
            const AppCard(child: Row(children: [
              Icon(Icons.lightbulb_outline_rounded, color: PennyPalTheme.sky),
              SizedBox(width: 12),
              Expanded(child: Text('No income, expenses or budget yet. Add your first income, record an expense, then set a monthly budget to see your progress here.', style: TextStyle(height: 1.4, fontWeight: FontWeight.w600))),
            ])),
            const SizedBox(height: 14),
          ],
          const SectionTitle('Quick actions'), const SizedBox(height: 10),
          // Links required by the SRS dashboard section: Add Income, Add
          // Expense, Budget, Transaction History, Learning, Feedback and
          // Contact Support, plus the assistant and goals.
          GridView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: wide ? 5 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 68), children: [
            _ActionTile('Add expense', Icons.remove_circle_outline, PennyPalTheme.sky, () => _openQuickAddFromDashboard(context, onRefresh)),
            _ActionTile('Add income', Icons.add_circle_outline, PennyPalTheme.mint, () => _openQuickAddFromDashboard(context, onRefresh, income: true)),
            _ActionTile('Budget', Icons.track_changes_outlined, PennyPalTheme.navy, () => onNavigate(2)),
            _ActionTile('History', Icons.receipt_long_outlined, PennyPalTheme.sky, () => onNavigate(1)),
            _ActionTile('My goals', Icons.flag_outlined, PennyPalTheme.amber, () => onNavigate(3)),
            _ActionTile('Learning', Icons.school_outlined, PennyPalTheme.mint, () => Navigator.of(context).push(pennyPalRoute(const LearningScreen()))),
            _ActionTile('Reports', Icons.insights_outlined, PennyPalTheme.navy, () => Navigator.of(context).push(pennyPalRoute(const ReportsScreen()))),
            _ActionTile('Ask PennyPal', Icons.auto_awesome, PennyPalTheme.navy, () => Navigator.of(context).push(pennyPalRoute(const AssistantScreen()))),
            _ActionTile('Feedback', Icons.rate_review_outlined, PennyPalTheme.sky, () => Navigator.of(context).push(pennyPalRoute(const FeedbackScreen()))),
            _ActionTile('Support', Icons.support_agent_outlined, PennyPalTheme.mint, () => Navigator.of(context).push(pennyPalRoute(const SupportScreen()))),
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

class _ActionTile extends StatelessWidget { final String title; final IconData icon; final Color color; final VoidCallback onTap; const _ActionTile(this.title, this.icon, this.color, this.onTap); @override Widget build(BuildContext context) => Semantics(button: true, label: title, excludeSemantics: true, child: MotionPress(onTap: onTap, child: AppCard(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)))])))); }

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
    afterNextFrame((_) {
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
  late String category = widget.income ? PennyPalService.incomeSources.first : 'Food';
  DateTime date = DateTime.now();
  bool busy = false;
  XFile? receipt;
  // Validation and save errors are shown inside the sheet. A SnackBar would be
  // drawn on the page behind the modal sheet, where the user cannot see it.
  String? error;

  @override
  void dispose() {
    amount.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      setState(() => error = 'Enter an amount greater than zero.');
      return;
    }
    if (value > 1000000000) {
      setState(() => error = 'That amount looks too large. Please check it.');
      return;
    }

    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });

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
        // For income the "category" is its source (Allowance, Scholarship...).
        'category_name': category,
        'description': desc.text.trim(),
        'date': PennyPalService.dateKey(date),
        'payment_mode': 'Cash',
        'receipt_image_url': receiptUrl,
      });

      final alert = saved['budget_alert'] as String?;
      final message = receiptPending
          ? 'Transaction saved. Receipt upload is waiting for internet.'
          : saved['pending_sync'] == true
              ? 'Saved on this device. It will sync when you are back online.'
              : alert ?? (widget.income ? 'Income saved.' : 'Expense saved.');

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
      setState(() {
        busy = false;
        error = 'Could not save this transaction. Please try again.';
      });
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: widget.income ? 'Date received' : 'Date spent',
    );
    if (picked != null && mounted) setState(() => date = picked);
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
      if (mounted) setState(() => error = 'Could not open the camera on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.income ? PennyPalService.incomeSources : PennyPalService.categories;
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
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦ '),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: options.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                onChanged: busy ? null : (v) => setState(() => category = v ?? category),
                decoration: InputDecoration(labelText: widget.income ? 'Source' : 'Category'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text('Date: ${PennyPalService.dateKey(date)}'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: desc,
                enabled: !busy,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: widget.income ? 'e.g. September allowance' : 'What did you spend on?',
                  counterText: '',
                ),
              ),
              if (!widget.income && PennyPalService.storageEnabled) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : pickReceipt,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(receipt == null ? 'Attach receipt photo (optional)' : 'Receipt attached'),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: PennyPalTheme.danger.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
                    child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700)),
                  ),
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
