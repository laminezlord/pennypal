import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

/// Colour for a spending progress bar: calm below the alert threshold, amber
/// once it is reached and red when the limit is exceeded.
Color budgetColor(num spent, num limit, {num threshold = 80}) {
  if (limit <= 0) return PennyPalTheme.sky;
  final percent = spent / limit * 100;
  if (percent > 100) return PennyPalTheme.danger;
  if (percent >= threshold) return const Color(0xFFE59E1A);
  return PennyPalTheme.mint;
}

class BudgetScreen extends StatefulWidget {
  /// Changes whenever the Budget tab is opened so the figures reload.
  final int refreshSignal;
  const BudgetScreen({super.key, this.refreshSignal = 0});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<dynamic> budgets = [];
  List<dynamic> tx = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(BudgetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal > 0 && widget.refreshSignal != oldWidget.refreshSignal) load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        PennyPalService.budgets(),
        PennyPalService.transactions(),
      ]);
      if (mounted) {
        setState(() {
          budgets = results[0];
          tx = results[1];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget data could not be loaded. Pull down to try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String get _month => DateFormat('yyyy-MM').format(DateTime.now());

  num spent(String category) => tx
      .where((x) =>
          x['type'] == 'EXPENSE' &&
          '${x['date']}'.startsWith(_month) &&
          (category == 'TOTAL' || '${x['category_detail']?['name'] ?? ''}' == category))
      .fold<num>(0, (total, x) => total + (num.tryParse('${x['amount']}') ?? 0));

  Map<String, dynamic>? budgetFor(String category) {
    for (final item in budgets) {
      if ('${item['month']}'.startsWith(_month) && '${item['category_id']}' == category) {
        return Map<String, dynamic>.from(item as Map);
      }
    }
    return null;
  }

  num limit(String category) => num.tryParse('${budgetFor(category)?['limit_amount'] ?? 0}') ?? 0;
  num threshold(String category) {
    final t = num.tryParse('${budgetFor(category)?['alert_threshold'] ?? 80}') ?? 80;
    return t <= 0 ? 80 : t;
  }

  Future<void> openEditor({String? category}) async {
    final existing = category == null ? null : budgetFor(category);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BudgetEditor(
        category: category,
        existing: existing,
      ),
    );

    // Wait until the sheet route has fully left the tree before refreshing
    // the parent. This avoids Flutter's _dependents.isEmpty assertion when a
    // StatefulBuilder/InheritedWidget is being deactivated.
    if (!mounted || result != true) return;
    afterNextFrame((_) {
      if (mounted) load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = limit('TOTAL');
    final totalSpent = spent('TOTAL');
    final double progress = total <= 0 ? 0.0 : (totalSpent / total).clamp(0, 1).toDouble();
    final remaining = total - totalSpent;
    final totalColor = budgetColor(totalSpent, total, threshold: threshold('TOTAL'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Set monthly budget',
            onPressed: () => openEditor(category: 'TOTAL'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            MotionReveal(delay: const Duration(milliseconds: 40), child: const GradientHeader(
              eyebrow: 'PLAN WITH PURPOSE',
              title: 'Give your money a job.',
              subtitle: 'Set a monthly limit, then add category guardrails.',
            )),
            const SizedBox(height: 16),
            if (loading)
              const LoadingCard()
            else
              MotionReveal(delay: const Duration(milliseconds: 120), child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Monthly budget • ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: total > 0 ? 'Edit monthly budget' : 'Set monthly budget',
                          onPressed: () => openEditor(category: 'TOTAL'),
                          icon: Icon(total > 0 ? Icons.edit_outlined : Icons.add),
                        ),
                      ],
                    ),
                    Text(
                      total > 0 ? money(total) : 'Not set yet',
                      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          minHeight: 10,
                          value: value,
                          color: totalColor,
                          backgroundColor: PennyPalTheme.line,
                          semanticsLabel: 'Monthly budget used',
                          semanticsValue: total > 0 ? '${(totalSpent / total * 100).round()} percent' : 'No budget set',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Spent ${money(totalSpent)}', style: const TextStyle(color: PennyPalTheme.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                        Text(
                          total > 0 ? '${(totalSpent / total * 100).round()}% used' : 'Set a limit',
                          style: const TextStyle(color: PennyPalTheme.muted, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: totalColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          remaining >= 0
                              ? '${money(remaining)} left to spend this month.'
                              : 'Over budget by ${money(remaining.abs())}. Review your spending or adjust your plan.',
                          style: TextStyle(fontWeight: FontWeight.w800, color: remaining >= 0 ? PennyPalTheme.ink : PennyPalTheme.danger),
                        ),
                      ),
                    ],
                  ],
                ),
              )),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Category limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                TextButton.icon(
                  onPressed: () => openEditor(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...PennyPalService.categories.asMap().entries.map((entry) {
              final category = entry.value;
              final categoryLimit = limit(category);
              final categorySpent = spent(category);
              final categoryProgress = categoryLimit <= 0 ? 0.0 : (categorySpent / categoryLimit).clamp(0, 1).toDouble();
              final color = budgetColor(categorySpent, categoryLimit, threshold: threshold(category));
              final over = categoryLimit > 0 && categorySpent > categoryLimit;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MotionReveal(delay: Duration(milliseconds: 280 + entry.key * 45), child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.category_outlined, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category, style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: categoryProgress),
                                duration: const Duration(milliseconds: 760),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => LinearProgressIndicator(
                                  minHeight: 7,
                                  value: value,
                                  color: color,
                                  backgroundColor: PennyPalTheme.line,
                                  semanticsLabel: '$category limit used',
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              categoryLimit > 0
                                  ? over
                                      ? '${money(categorySpent)} of ${money(categoryLimit)} • over by ${money(categorySpent - categoryLimit)}'
                                      : '${money(categorySpent)} of ${money(categoryLimit)} • ${money(categoryLimit - categorySpent)} left'
                                  : categorySpent > 0
                                      ? '${money(categorySpent)} spent • no limit set'
                                      : 'No limit set',
                              style: TextStyle(color: over ? PennyPalTheme.danger : PennyPalTheme.muted, fontSize: 11, fontWeight: over ? FontWeight.w800 : FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: categoryLimit > 0 ? 'Edit $category limit' : 'Set $category limit',
                        onPressed: () => openEditor(category: category),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                )),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BudgetEditor extends StatefulWidget {
  final String? category;
  final Map<String, dynamic>? existing;

  const _BudgetEditor({this.category, this.existing});

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  late final TextEditingController controller;
  late String selected;
  late int alertThreshold;
  bool saving = false;
  // Shown inside the sheet; a SnackBar would appear behind the modal sheet.
  String? error;

  num get _existingLimit => num.tryParse('${widget.existing?['limit_amount'] ?? 0}') ?? 0;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: _existingLimit > 0 ? _existingLimit.toStringAsFixed(2) : '');
    selected = widget.category ?? PennyPalService.categories.first;
    final t = (num.tryParse('${widget.existing?['alert_threshold'] ?? 80}') ?? 80).round();
    alertThreshold = const [50, 75, 80, 90].contains(t) ? t : 80;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(controller.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      setState(() => error = 'Enter a budget amount greater than zero.');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });
    try {
      await PennyPalService.addBudget({
        'month': DateFormat('yyyy-MM').format(DateTime.now()),
        'category_id': widget.category == 'TOTAL' ? 'TOTAL' : selected,
        'limit_amount': value,
        'alert_threshold': alertThreshold,
      });

      if (!mounted) return;
      // Reset local state before popping the route. Never call setState after
      // Navigator.pop because the sheet may already be deactivating.
      setState(() => saving = false);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = 'Could not save the budget. Check your connection and try again.';
      });
    }
  }

  Future<void> remove() async {
    final id = '${widget.existing?['id'] ?? ''}';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove this limit?'),
        content: const Text('Your transactions stay as they are. Only the limit for this month is removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await PennyPalService.deleteBudget(id);
      if (!mounted) return;
      setState(() => saving = false);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = 'Could not remove the limit. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.category == 'TOTAL'
        ? 'Monthly budget'
        : widget.category == null
            ? 'Category limit'
            : '${widget.category} limit';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Set a limit for ${DateFormat('MMMM yyyy').format(DateTime.now())}. PennyPal warns you when spending reaches the alert level.',
                style: const TextStyle(color: PennyPalTheme.muted),
              ),
              const SizedBox(height: 16),
              if (widget.category == null) ...[
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  items: PennyPalService.categories.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value != null && mounted) setState(() => selected = value);
                        },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                enabled: !saving,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
                decoration: const InputDecoration(labelText: 'Limit amount', prefixText: '₦ '),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: alertThreshold,
                items: const [50, 75, 80, 90].map((t) => DropdownMenuItem<int>(value: t, child: Text('Warn me at $t%'))).toList(),
                onChanged: saving ? null : (v) => setState(() => alertThreshold = v ?? alertThreshold),
                decoration: const InputDecoration(labelText: 'Alert threshold'),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save limit'),
                ),
              ),
              if (_existingLimit > 0) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: saving ? null : remove,
                    style: TextButton.styleFrom(foregroundColor: PennyPalTheme.danger),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove this limit'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
