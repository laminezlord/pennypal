import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../services/pennypal_service.dart';
import '../widgets/penny_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? report;
  bool loading = true;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final result = await PennyPalService.report();
      if (mounted) setState(() => report = result);
    } catch (_) {}
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Map<String, num>.from(report?['by_category'] ?? {});
    final income = Map<String, num>.from(report?['monthly_income'] ?? {});
    final expense = Map<String, num>.from(report?['monthly_expense'] ?? {});
    final months = {...income.keys, ...expense.keys}.toList()..sort();
    final totalIncome = report?['total_income'] as num? ?? 0;
    final totalExpense = report?['total_expense'] as num? ?? 0;
    final balance = report?['balance'] as num? ?? 0;
    final topCategory = report?['top_category'];
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & trends', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            MotionReveal(delay: const Duration(milliseconds: 40), child: const GradientHeader(eyebrow: 'SEE THE PATTERN', title: 'Understand where it goes.', subtitle: 'Turn your recorded activity into simple spending and progress insights.')),
            const SizedBox(height: 16),
            if (loading) const LoadingCard()
            else ...[
              LayoutBuilder(builder: (context, c) {
                final two = c.maxWidth >= 620;
                final cards = [
                  MotionReveal(delay: const Duration(milliseconds: 80), child: _SummaryCard('Income', totalIncome, Icons.south_west_rounded, PennyPalTheme.mint)),
                  MotionReveal(delay: const Duration(milliseconds: 140), child: _SummaryCard('Expenses', totalExpense, Icons.north_east_rounded, PennyPalTheme.sky)),
                  MotionReveal(delay: const Duration(milliseconds: 200), child: _SummaryCard('Balance', balance, Icons.account_balance_wallet_outlined, balance >= 0 ? PennyPalTheme.navy : PennyPalTheme.danger)),
                ];
                return two
                    ? Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 10)]])
                    : Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i < cards.length - 1) const SizedBox(height: 10)]]);
              }),
              const SizedBox(height: 14),
              MotionReveal(delay: const Duration(milliseconds: 260), child: AppCard(child: Row(children: [
                const Icon(Icons.category_outlined, color: PennyPalTheme.sky), const SizedBox(width: 10),
                Expanded(child: Text(topCategory == null ? 'Add expenses to discover your highest-spend category.' : 'Highest spending category: $topCategory', style: const TextStyle(fontWeight: FontWeight.w800))),
              ]))),
              const SizedBox(height: 14),
              if (sorted.isEmpty)
                const EmptyState(icon: Icons.insights_outlined, title: 'Not enough data yet', message: 'Add a few expenses and income entries and your reports will start showing patterns.')
              else ...[
                MotionReveal(delay: const Duration(milliseconds: 320), child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Spending by category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  SizedBox(height: 230, child: PieChart(PieChartData(centerSpaceRadius: 48, sectionsSpace: 2, sections: _pieSections(sorted)))),
                ]))),
                const SizedBox(height: 12),
                ...sorted.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: MotionReveal(delay: Duration(milliseconds: 400 + e.key * 55), child: AppCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Expanded(child: Text(e.value.key, style: const TextStyle(fontWeight: FontWeight.w800))), Text(money(e.value.value), style: const TextStyle(fontWeight: FontWeight.w900))]))))),
              ],
              if (months.isNotEmpty) ...[
                const SizedBox(height: 12),
                MotionReveal(delay: const Duration(milliseconds: 520), child: _MonthlyTrend(months: months, income: income, expense: expense)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _pieSections(List<MapEntry<String, num>> entries) {
    const colors = [PennyPalTheme.navy, PennyPalTheme.mint, PennyPalTheme.sky, PennyPalTheme.amber, Color(0xFF8B7CF6), Color(0xFFEF8B6B), Color(0xFF5AB0A6), Color(0xFF9AA6B5)];
    return entries.take(8).toList().asMap().entries.map((item) {
      final entry = item.value;
      return PieChartSectionData(value: entry.value.toDouble(), color: colors[item.key % colors.length], title: '${entry.key}\n${money(entry.value)}', radius: 70, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white));
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label; final num value; final IconData icon; final Color accent;
  const _SummaryCard(this.label, this.value, this.icon, this.accent);
  @override Widget build(BuildContext context) => AppCard(child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: accent)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(money(value), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))]))]));
}

class _MonthlyTrend extends StatelessWidget {
  final List<String> months; final Map<String, num> income; final Map<String, num> expense;
  const _MonthlyTrend({required this.months, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final maxValue = [...income.values, ...expense.values].fold<num>(0, (a, b) => a > b ? a : b);
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Monthly income vs expenses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('A simple trend view based on recorded transactions.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
      const SizedBox(height: 18),
      SizedBox(height: 250, child: LineChart(LineChartData(
        minY: 0, maxY: maxValue <= 0 ? 1 : maxValue.toDouble() * 1.15,
        gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) {
            final i = value.toInt(); if (i < 0 || i >= months.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 8), child: Text(months[i].length >= 7 ? months[i].substring(2) : months[i], style: const TextStyle(fontSize: 10)));
          })),
        ),
        lineBarsData: [_line(income, PennyPalTheme.mint), _line(expense, PennyPalTheme.sky)],
      ))),
      const SizedBox(height: 8),
      const Row(children: [Icon(Icons.circle, size: 9, color: PennyPalTheme.mint), SizedBox(width: 5), Text('Income', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), SizedBox(width: 14), Icon(Icons.circle, size: 9, color: PennyPalTheme.sky), SizedBox(width: 5), Text('Expenses', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
    ]));
  }

  LineChartBarData _line(Map<String, num> values, Color color) => LineChartBarData(
    isCurved: true, color: color, barWidth: 3, dotData: const FlDotData(show: true), belowBarData: BarAreaData(show: false),
    spots: months.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (values[e.value] ?? 0).toDouble())).toList(),
  );
}
