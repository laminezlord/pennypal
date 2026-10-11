import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class SavingsScreen extends StatefulWidget {
  /// Changes whenever the Goals tab is opened so the goals reload.
  final int refreshSignal;
  const SavingsScreen({super.key, this.refreshSignal = 0});
  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<dynamic> goals = [];
  bool loading = true;
  bool creating = false;
  String? formError;
  final name = TextEditingController();
  final target = TextEditingController();
  final saved = TextEditingController();
  final monthly = TextEditingController();
  DateTime date = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(SavingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal > 0 && widget.refreshSignal != oldWidget.refreshSignal) load();
  }

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    saved.dispose();
    monthly.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await PennyPalService.goals();
      if (mounted) setState(() => goals = result);
    } catch (_) {
      // Keep the current list if the cloud is temporarily unavailable.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  num? _amount(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim());

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      helpText: 'Target date',
    );
    if (picked != null && mounted) setState(() => date = picked);
  }

  Future<void> add() async {
    final t = _amount(target);
    final s = saved.text.trim().isEmpty ? 0 : _amount(saved);
    final m = _amount(monthly);
    String? problem;
    if (name.text.trim().isEmpty) {
      problem = 'Give your goal a name.';
    } else if (t == null || t <= 0) {
      problem = 'Enter a target amount greater than zero.';
    } else if (s == null || s < 0) {
      problem = 'Current savings must be zero or more.';
    } else if (s >= t) {
      problem = 'Current savings already reach the target. Choose a bigger target.';
    } else if (m == null || m <= 0) {
      problem = 'Enter a monthly contribution greater than zero.';
    } else if (!date.isAfter(DateTime.now())) {
      problem = 'Choose a target date in the future.';
    }
    if (problem != null) {
      setState(() => formError = problem);
      return;
    }
    setState(() {
      creating = true;
      formError = null;
    });
    try {
      await PennyPalService.addGoal({
        'goal_name': name.text.trim(),
        'target_amount': t,
        'current_amount': s,
        'target_date': DateFormat('yyyy-MM-dd').format(date),
        'monthly_contribution': m,
      });
      if (!mounted) return;
      name.clear();
      target.clear();
      saved.clear();
      monthly.clear();
      await load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal created. Every contribution counts!')));
    } catch (_) {
      if (mounted) setState(() => formError = 'Could not create the goal. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Completed goals move to history automatically (SRS: completed goals are
    // archived and visible in goal history).
    final active = goals.where((g) => g['status'] == 'active').toList();
    final history = goals.where((g) => g['status'] != 'active').toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings goals', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(tooltip: 'Refresh', onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            MotionReveal(delay: const Duration(milliseconds: 40), child: const GradientHeader(eyebrow: 'SMALL STEPS • BIG TARGETS', title: 'Make saving visible.', subtitle: 'Set a target, contribute monthly, earn milestones and see an estimated finish date.')),
            const SizedBox(height: 16),
            MotionReveal(delay: const Duration(milliseconds: 120), child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Create a goal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: name, maxLength: 60, decoration: const InputDecoration(labelText: 'Goal name', hintText: 'Laptop, emergency fund, course...', counterText: '')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target', prefixText: '₦ '))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: saved, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Saved so far', prefixText: '₦ ', hintText: '0'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: monthly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monthly', prefixText: '₦ '))),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(DateFormat('dd MMM yyyy').format(date)),
                  ),
                ),
              ]),
              if (formError != null) ...[
                const SizedBox(height: 10),
                Semantics(liveRegion: true, child: Text(formError!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700))),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: creating ? null : add,
                  child: creating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create goal'),
                ),
              ),
            ]))),
            const SizedBox(height: 22),
            const SectionTitle('Active goals'),
            const SizedBox(height: 10),
            if (loading) const LoadingCard(),
            if (!loading && active.isEmpty) const EmptyState(icon: Icons.flag_outlined, title: 'No active goals', message: 'Create a goal and PennyPal will keep the target visible.'),
            ...active.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MotionReveal(delay: Duration(milliseconds: 180 + e.key * 70), child: _GoalCard(e.value, onChanged: load)))),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 10),
              const SectionTitle('Goal history'),
              const SizedBox(height: 4),
              const Text('Completed and archived goals.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
              const SizedBox(height: 10),
              ...history.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: MotionReveal(delay: Duration(milliseconds: 180 + e.key * 60), child: _GoalCard(e.value, onChanged: load)))),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final dynamic x;
  final Future<void> Function() onChanged;
  const _GoalCard(this.x, {required this.onChanged});

  String _motivation(num progress) {
    if (progress >= 100) return 'Goal achieved. Well done!';
    if (progress >= 75) return 'Almost there. Keep going!';
    if (progress >= 50) return 'Halfway there. Great consistency!';
    if (progress >= 25) return 'Great start. Momentum is building.';
    return 'Every contribution moves you closer.';
  }

  Future<void> _contribute(BuildContext context) async {
    final controller = TextEditingController();
    final remaining = (x['remaining'] as num?) ?? 0;
    String? error;
    final amount = await showDialog<double>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setDialog) => AlertDialog(
          title: Text('Add to ${x['goal_name']}'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${money(remaining)} still needed.', style: const TextStyle(color: PennyPalTheme.muted)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Contribution', prefixText: '₦ ')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(controller.text.replaceAll(',', '').trim());
                if (v == null || v <= 0) {
                  setDialog(() => error = 'Enter an amount greater than zero.');
                  return;
                }
                Navigator.pop(dialog, v);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (amount == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await PennyPalService.contributeToGoal('${x['id']}', amount);
      messenger.showSnackBar(SnackBar(content: Text(amount >= remaining ? 'Goal reached! It has moved to your goal history.' : 'Savings contribution added.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not update the goal. Please try again.')));
    }
    // Refresh after the dialog route has fully left the tree.
    afterNextFrame((_) {
      if (context.mounted) onChanged();
    });
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this goal?'),
        content: Text('"${x['goal_name']}" and its progress will be removed. Archive it instead if you want to keep it in your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (x['progress'] as num?) ?? 0;
    final progress = progressPercent.toDouble() / 100;
    final target = (x['target_amount'] as num?) ?? 0;
    final current = (x['current_amount'] as num?) ?? 0;
    final remaining = (x['remaining'] as num?) ?? 0;
    final monthly = (x['monthly_contribution'] as num?) ?? 0;
    final complete = progress >= 1 || x['status'] == 'completed';
    final archived = x['status'] == 'archived';
    final remainingMonths = (x['estimated_months'] as num?)?.toInt() ?? 0;
    final milestone = x['milestone'] ?? 0;
    final accent = complete ? PennyPalTheme.mint : PennyPalTheme.sky;

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('${x['goal_name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)),
          child: Text(complete ? 'Completed' : archived ? 'Archived' : '$progressPercent%', style: TextStyle(fontWeight: FontWeight.w900, color: accent)),
        ),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0, 1)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LinearProgressIndicator(
            minHeight: 12,
            value: value,
            color: accent,
            backgroundColor: PennyPalTheme.line,
            semanticsLabel: '${x['goal_name']} progress',
            semanticsValue: '$progressPercent percent',
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${money(current)} saved', style: const TextStyle(fontWeight: FontWeight.w800)),
        Text('of ${money(target)}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
      ]),
      const SizedBox(height: 6),
      if (!complete) Text('${money(remaining)} to go • ${money(monthly)} monthly • target ${x['target_date']}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
      if (!complete && !archived && monthly > 0) Text('Estimated completion: about $remainingMonths month${remainingMonths == 1 ? '' : 's'}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.workspace_premium_outlined, size: 18, color: milestone > 0 ? PennyPalTheme.amber : PennyPalTheme.muted),
        const SizedBox(width: 6),
        Expanded(child: Text('${x['badge']} • ${complete ? _motivation(100) : milestone == 0 ? 'Next milestone: 25%' : 'Latest milestone: $milestone%'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PennyPalTheme.muted))),
        if (!complete && !archived) TextButton.icon(onPressed: () => _contribute(context), icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('Contribute')),
      ]),
      if (!complete && !archived) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(spacing: 6, children: [25, 50, 75, 100].map((m) {
            final reached = progressPercent >= m;
            return Chip(
              avatar: Icon(reached ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: reached ? PennyPalTheme.mint : PennyPalTheme.muted),
              label: Text('$m%'),
              visualDensity: VisualDensity.compact,
              backgroundColor: (reached ? PennyPalTheme.mint : PennyPalTheme.canvas).withValues(alpha: .14),
            );
          }).toList()),
        ),
        const SizedBox(height: 6),
        Text(_motivation(progressPercent), style: const TextStyle(fontSize: 12, color: PennyPalTheme.ink, fontWeight: FontWeight.w600)),
      ],
      Align(
        alignment: Alignment.centerRight,
        child: PopupMenuButton<String>(
          tooltip: 'Goal options',
          onSelected: (value) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              if (value == 'delete') {
                if (!await _confirmDelete(context)) return;
                await PennyPalService.deleteGoal(x['id']);
                messenger.showSnackBar(const SnackBar(content: Text('Goal deleted.')));
              } else if (value == 'complete') {
                await PennyPalService.updateGoal(x['id'], {'status': 'completed', 'current_amount': target});
                messenger.showSnackBar(const SnackBar(content: Text('Goal completed and moved to history.')));
              } else if (value == 'archive') {
                await PennyPalService.archiveGoal(x['id']);
              } else if (value == 'restore') {
                await PennyPalService.restoreGoal(x['id']);
              }
              afterNextFrame((_) {
                if (context.mounted) onChanged();
              });
            } catch (_) {
              messenger.showSnackBar(const SnackBar(content: Text('That goal action failed. Please try again.')));
            }
          },
          itemBuilder: (_) => [
            if (!complete && !archived) const PopupMenuItem(value: 'complete', child: Text('Mark complete')),
            if (!archived && !complete) const PopupMenuItem(value: 'archive', child: Text('Archive goal')),
            if (archived) const PopupMenuItem(value: 'restore', child: Text('Restore goal')),
            const PopupMenuItem(value: 'delete', child: Text('Delete goal')),
          ],
          child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.more_horiz)),
        ),
      ),
    ]));
  }
}
