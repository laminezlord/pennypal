import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});
  @override State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<dynamic> goals = [];
  bool loading = true;
  final name = TextEditingController();
  final target = TextEditingController();
  final monthly = TextEditingController();
  DateTime date = DateTime.now().add(const Duration(days: 90));

  @override void initState() { super.initState(); load(); }
  @override void dispose() { name.dispose(); target.dispose(); monthly.dispose(); super.dispose(); }

  Future<void> load() async {
    try {
      final result = await PennyPalService.goals();
      if (mounted) setState(() => goals = result);
    } catch (_) {}
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> add() async {
    final t = double.tryParse(target.text.replaceAll(',', ''));
    final m = double.tryParse(monthly.text.replaceAll(',', ''));
    if (name.text.trim().isEmpty || t == null || m == null || t <= 0 || m <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete the goal name, target and monthly contribution.')));
      return;
    }
    if (date.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future target date.')));
      return;
    }
    try {
      await PennyPalService.addGoal({
        'goal_name': name.text.trim(), 'target_amount': t, 'current_amount': 0,
        'target_date': DateFormat('yyyy-MM-dd').format(date), 'monthly_contribution': m,
      });
      if (!mounted) return;
      name.clear();
      target.clear();
      monthly.clear();
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create goal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = goals.where((g) => g['status'] != 'archived').toList();
    final archived = goals.where((g) => g['status'] == 'archived').toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings goals', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Choose target date',
            onPressed: () async {
              final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime(2100));
              if (picked != null && mounted) setState(() => date = picked);
            },
            icon: const Icon(Icons.event_outlined),
          ),
        ],
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
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Goal name', hintText: 'Laptop, emergency fund, course...')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target', prefixText: '₦ '))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: monthly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monthly', prefixText: '₦ '))),
              ]),
              const SizedBox(height: 10),
              Text('Target date: ${DateFormat('dd MMM yyyy').format(date)}', style: const TextStyle(color: PennyPalTheme.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: add, child: const Text('Create goal'))),
            ]))),
            const SizedBox(height: 22),
            const SectionTitle('Active goals'),
            const SizedBox(height: 10),
            if (loading) const LoadingCard(),
            if (!loading && active.isEmpty) const EmptyState(icon: Icons.flag_outlined, title: 'No active goals', message: 'Create a goal and PennyPal will keep the target visible.'),
            ...active.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MotionReveal(delay: Duration(milliseconds: 180 + e.key * 70), child: _GoalCard(e.value, onChanged: load)))),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: 10),
              const SectionTitle('Archived goals'),
              const SizedBox(height: 10),
              ...archived.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: MotionReveal(delay: Duration(milliseconds: 180 + e.key * 60), child: _GoalCard(e.value, onChanged: load)))),
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

  Future<void> _contribute(BuildContext context) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Add to ${x['goal_name']}'),
        content: TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Contribution', prefixText: '₦ ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
          FilledButton(onPressed: () { final v = double.tryParse(controller.text.replaceAll(',', '')); if (v != null && v > 0) Navigator.pop(dialog, v); }, child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;
    try {
      await PennyPalService.contributeToGoal('${x['id']}', amount);

      // Do not rebuild the parent while the dialog route is still being
      // deactivated. That can trigger Flutter's _dependents.isEmpty
      // assertion on Android. Refresh only after the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await onChanged();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Savings contribution added.')),
        );
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update goal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((x['progress'] as num?)?.toDouble() ?? 0) / 100;
    final target = (x['target_amount'] as num?) ?? 0;
    final current = (x['current_amount'] as num?) ?? 0;
    final monthly = (x['monthly_contribution'] as num?) ?? 0;
    final complete = progress >= 1 || x['status'] == 'completed';
    final archived = x['status'] == 'archived';
    final remainingMonths = (x['estimated_months'] as num?)?.toInt() ?? 0;
    final milestone = x['milestone'] ?? 0;

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('${x['goal_name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: (complete ? PennyPalTheme.mint : PennyPalTheme.sky).withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Text(complete ? 'Completed' : archived ? 'Archived' : '${x['progress'] ?? 0}%', style: TextStyle(fontWeight: FontWeight.w900, color: complete ? PennyPalTheme.mint : PennyPalTheme.sky))),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        height: 150,
        child: BarChart(
          BarChartData(
            maxY: target <= 0 ? 1 : target.toDouble(),
            minY: 0,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            barGroups: [BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: current.toDouble().clamp(0, target.toDouble()).toDouble(), width: 34, borderRadius: BorderRadius.circular(8))])],
          ),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${money(current)} saved', style: const TextStyle(fontWeight: FontWeight.w800)), Text('${money(target)} target', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12))]),
      const SizedBox(height: 8),
      Text('${money(monthly)} monthly • target ${x['target_date']}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
      if (!complete && monthly > 0) Text('Estimated completion: about $remainingMonths month(s)', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.workspace_premium_outlined, size: 18, color: milestone > 0 ? PennyPalTheme.amber : PennyPalTheme.muted),
        const SizedBox(width: 6),
        Expanded(child: Text('${x['badge']} • ${milestone == 0 ? 'Next milestone: 25%' : 'Latest milestone: $milestone%'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PennyPalTheme.muted))),
        if (!complete && !archived) TextButton.icon(onPressed: () => _contribute(context), icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('Contribute')),
      ]),
      if (!complete && !archived) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 6, children: [25, 50, 75, 100].map((m) => Chip(label: Text('$m%'), visualDensity: VisualDensity.compact, backgroundColor: (progress * 100 >= m ? PennyPalTheme.mint : PennyPalTheme.canvas).withValues(alpha: .14))).toList())),
      Align(
        alignment: Alignment.centerRight,
        child: PopupMenuButton<String>(
          onSelected: (value) async {
            try {
              if (value == 'delete') {
                await PennyPalService.deleteGoal(x['id']);
              } else if (value == 'complete') {
                await PennyPalService.updateGoal(x['id'], {'status': 'completed', 'current_amount': target});
              } else if (value == 'archive') {
                await PennyPalService.archiveGoal(x['id']);
              } else if (value == 'restore') {
                await PennyPalService.restoreGoal(x['id']);
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) onChanged();
              });
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goal action failed: $e')));
              }
            }
          },
          itemBuilder: (_) => [
            if (!complete && !archived) const PopupMenuItem(value: 'complete', child: Text('Mark complete')),
            if (!archived) const PopupMenuItem(value: 'archive', child: Text('Archive goal')),
            if (archived) const PopupMenuItem(value: 'restore', child: Text('Restore goal')),
            const PopupMenuItem(value: 'delete', child: Text('Delete goal')),
          ],
          child: const Icon(Icons.more_horiz),
        ),
      ),
    ]));
  }
}
