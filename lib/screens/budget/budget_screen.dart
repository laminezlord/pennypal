import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Budget data could not be loaded: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  num spent(String category) {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    return tx
        .where((x) =>
            x['type'] == 'EXPENSE' &&
            '${x['date']}'.startsWith(month) &&
            (category == 'TOTAL' ||
                '${x['category_detail']?['name'] ?? ''}' == category))
        .fold<num>(0, (total, x) => total + (num.tryParse('${x['amount']}') ?? 0));
  }

  num limit(String category) {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    for (final item in budgets) {
      if ('${item['month']}'.startsWith(month) &&
          '${item['category_id']}' == category) {
        return num.tryParse('${item['limit_amount']}') ?? 0;
      }
    }
    return 0;
  }

  Future<void> openEditor({String? category}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BudgetEditor(
        category: category,
        existingLimit: category == null ? 0 : limit(category),
      ),
    );

    // Wait until the sheet route has fully left the tree before refreshing
    // the parent. This avoids Flutter's _dependents.isEmpty assertion when a
    // StatefulBuilder/InheritedWidget is being deactivated.
    if (!mounted || result != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = limit('TOTAL');
    final totalSpent = spent('TOTAL');
    final double progress = total <= 0
        ? 0.0
        : (totalSpent / total).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Add budget',
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly budget',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => openEditor(category: 'TOTAL'),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    Text(
                      total > 0 ? money(total) : 'Not set yet',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent ${money(totalSpent)}',
                          style: const TextStyle(
                            color: PennyPalTheme.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          total > 0
                              ? '${(progress * 100).toStringAsFixed(0)}% used'
                              : 'Set a limit',
                          style: const TextStyle(
                            color: PennyPalTheme.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category limits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
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
              final categoryProgress = categoryLimit <= 0
                  ? 0.0
                  : (categorySpent / categoryLimit).clamp(0, 1).toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MotionReveal(delay: Duration(milliseconds: 280 + entry.key * 45), child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: PennyPalTheme.sky.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: PennyPalTheme.sky,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
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
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              categoryLimit > 0
                                  ? '${money(categorySpent)} of ${money(categoryLimit)}'
                                  : 'No limit set',
                              style: const TextStyle(
                                color: PennyPalTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit limit',
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
  final num existingLimit;

  const _BudgetEditor({this.category, required this.existingLimit});

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  late final TextEditingController controller;
  late String selected;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.existingLimit > 0
          ? widget.existingLimit.toStringAsFixed(2)
          : '',
    );
    selected = widget.category ?? PennyPalService.categories.first;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(controller.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid budget amount.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await PennyPalService.addBudget({
        'month': DateFormat('yyyy-MM').format(DateTime.now()),
        'category_id': widget.category == 'TOTAL' ? 'TOTAL' : selected,
        'limit_amount': value,
        'alert_threshold': 80,
      });

      if (!mounted) return;
      // Reset local state before popping the route. Never call setState after
      // Navigator.pop because the sheet may already be deactivating.
      setState(() => saving = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save budget: $e')),
      );
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
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Set a limit for the current month.',
                style: TextStyle(color: PennyPalTheme.muted),
              ),
              const SizedBox(height: 16),
              if (widget.category == null) ...[
                DropdownButtonFormField<String>(
                  value: selected,
                  items: PennyPalService.categories
                      .map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ))
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value != null && mounted) {
                            setState(() => selected = value);
                          }
                        },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Limit amount',
                  prefixText: '₦ ',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save limit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

