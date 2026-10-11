import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../services/pennypal_service.dart';
import '../widgets/penny_widgets.dart';

const _chartColors = [PennyPalTheme.navy, PennyPalTheme.mint, PennyPalTheme.sky, Color(0xFFE59E1A), Color(0xFF8B7CF6), Color(0xFFEF8B6B), Color(0xFF5AB0A6), Color(0xFF9AA6B5)];

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> tx = [];
  bool loading = true;
  bool thisMonthOnly = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final result = await PennyPalService.report();
      if (mounted) setState(() => tx = List<dynamic>.from(result['transactions'] as List? ?? const []));
    } catch (_) {
      // Keep the previous figures if the cloud is temporarily unavailable.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final scoped = thisMonthOnly ? tx.where((x) => '${x['date']}'.startsWith(monthKey)).toList() : tx;

    num totalIncome = 0, totalExpense = 0;
    final categories = <String, num>{};
    for (final x in scoped) {
      final amount = num.tryParse('${x['amount']}') ?? 0;
      if (x['type'] == 'INCOME') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
        final c = '${x['category_detail']?['name'] ?? 'Miscellaneous'}';
        categories[c] = (categories[c] ?? 0) + amount;
      }
    }
    final balance = totalIncome - totalExpense;
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // The trend always covers the last six months so the comparison is useful.
    final income = <String, num>{};
    final expense = <String, num>{};
    for (final x in tx) {
      final date = '${x['date']}';
      if (date.length < 7) continue;
      final m = date.substring(0, 7);
      final amount = num.tryParse('${x['amount']}') ?? 0;
      if (x['type'] == 'INCOME') {
        income[m] = (income[m] ?? 0) + amount;
      } else {
        expense[m] = (expense[m] ?? 0) + amount;
      }
    }
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateFormat('yyyy-MM').format(DateTime(now.year, now.month - i))];
    final hasTrend = months.any((m) => (income[m] ?? 0) > 0 || (expense[m] ?? 0) > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & trends', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(tooltip: 'Refresh', onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            MotionReveal(delay: const Duration(milliseconds: 40), child: const GradientHeader(eyebrow: 'SEE THE PATTERN', title: 'Understand where it goes.', subtitle: 'Turn your recorded activity into simple spending and progress insights.')),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(DateFormat('MMMM').format(now)), icon: const Icon(Icons.calendar_today_outlined, size: 16)),
                const ButtonSegment(value: false, label: Text('All time'), icon: Icon(Icons.all_inclusive, size: 16)),
              ],
              selected: {thisMonthOnly},
              onSelectionChanged: (s) => setState(() => thisMonthOnly = s.first),
            ),
            const SizedBox(height: 14),
            if (loading)
              const LoadingCard()
            else ...[
              LayoutBuilder(builder: (context, c) {
                final two = c.maxWidth >= 620;
                final cards = [
                  _SummaryCard('Income', totalIncome, Icons.south_west_rounded, PennyPalTheme.mint),
                  _SummaryCard('Expenses', totalExpense, Icons.north_east_rounded, PennyPalTheme.sky),
                  _SummaryCard('Balance', balance, Icons.account_balance_wallet_outlined, balance >= 0 ? PennyPalTheme.navy : PennyPalTheme.danger),
                ];
                return two
                    ? Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 10)]])
                    : Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i < cards.length - 1) const SizedBox(height: 10)]]);
              }),
              const SizedBox(height: 14),
              AppCard(child: Row(children: [
                const Icon(Icons.lightbulb_outline_rounded, color: PennyPalTheme.sky),
                const SizedBox(width: 10),
                Expanded(child: Text(_insight(sorted, totalIncome, totalExpense), style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35))),
              ])),
              const SizedBox(height: 14),
              if (sorted.isEmpty)
                EmptyState(icon: Icons.insights_outlined, title: 'No expenses ${thisMonthOnly ? 'this month' : 'yet'}', message: 'Add a few expenses and your reports will start showing patterns.')
              else ...[
                AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Spending by category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  Semantics(
                    label: 'Pie chart of spending by category. ${sorted.map((e) => '${e.key} ${money(e.value)}').join(', ')}',
                    excludeSemantics: true,
                    child: SizedBox(height: 220, child: PieChart(PieChartData(centerSpaceRadius: 46, sectionsSpace: 2, sections: _pieSections(sorted, totalExpense)))),
                  ),
                ])),
                const SizedBox(height: 12),
                ...sorted.take(8).toList().asMap().entries.map((e) {
                  final share = totalExpense <= 0 ? 0 : e.value.value / totalExpense * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: _chartColors[e.key % _chartColors.length], shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.value.key, style: const TextStyle(fontWeight: FontWeight.w800))),
                        Text('${share.toStringAsFixed(0)}%  ', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(money(e.value.value), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  );
                }),
              ],
              if (hasTrend) ...[
                const SizedBox(height: 12),
                _MonthlyTrend(months: months, income: income, expense: expense),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _insight(List<MapEntry<String, num>> sorted, num income, num expense) {
    if (income == 0 && expense == 0) return 'No activity recorded for this period yet.';
    final parts = <String>[];
    if (sorted.isNotEmpty) parts.add('Your highest spending category is ${sorted.first.key} (${money(sorted.first.value)}).');
    if (income > 0) {
      final rate = (income - expense) / income * 100;
      parts.add(rate >= 0 ? 'You kept ${rate.toStringAsFixed(0)}% of your income.' : 'You spent ${money(expense - income)} more than you received.');
    }
    return parts.join(' ');
  }

  List<PieChartSectionData> _pieSections(List<MapEntry<String, num>> entries, num total) {
    return entries.take(8).toList().asMap().entries.map((item) {
      final entry = item.value;
      final share = total <= 0 ? 0 : entry.value / total * 100;
      // Small slices get no label; the legend below names every category.
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: _chartColors[item.key % _chartColors.length],
        title: share >= 8 ? '${share.toStringAsFixed(0)}%' : '',
        radius: 64,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
      );
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final num value;
  final IconData icon;
  final Color accent;
  const _SummaryCard(this.label, this.value, this.icon, this.accent);
  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: accent)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(money(value), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: value < 0 ? PennyPalTheme.danger : PennyPalTheme.ink)),
            ]),
          ),
        ]),
      );
}

class _MonthlyTrend extends StatelessWidget {
  final List<String> months;
  final Map<String, num> income;
  final Map<String, num> expense;
  const _MonthlyTrend({required this.months, required this.income, required this.expense});

  static String _compact(num v) => NumberFormat.compact().format(v);

  @override
  Widget build(BuildContext context) {
    final maxValue = months.fold<num>(0, (a, m) {
      final hi = (income[m] ?? 0) > (expense[m] ?? 0) ? (income[m] ?? 0) : (expense[m] ?? 0);
      return hi > a ? hi : a;
    });
    final maxY = maxValue <= 0 ? 1.0 : maxValue.toDouble() * 1.15;
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Monthly income vs expenses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('The last six months of recorded transactions.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
      const SizedBox(height: 18),
      Semantics(
        label: 'Bar chart of monthly income and expenses. ${months.map((m) => '$m income ${money(income[m] ?? 0)}, expenses ${money(expense[m] ?? 0)}').join('; ')}',
        excludeSemantics: true,
        child: SizedBox(
          height: 230,
          child: BarChart(BarChartData(
            minY: 0,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4, getDrawingHorizontalLine: (_) => const FlLine(color: PennyPalTheme.line, strokeWidth: 1)),
            barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem('${rodIndex == 0 ? 'Income' : 'Expenses'}\n${money(rod.toY)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)))),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) => value >= maxY * .99 ? const SizedBox.shrink() : Text(_compact(value), style: const TextStyle(fontSize: 10, color: PennyPalTheme.muted)),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                // One label per month: without an interval fl_chart also asks
                // for fractional positions, which all rounded to the same month.
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (value != i || i < 0 || i >= months.length) return const SizedBox.shrink();
                  final d = DateTime.tryParse('${months[i]}-01');
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(d == null ? months[i] : DateFormat('MMM').format(d), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)));
                },
              )),
            ),
            barGroups: [
              for (var i = 0; i < months.length; i++)
                BarChartGroupData(x: i, barsSpace: 4, barRods: [
                  BarChartRodData(toY: (income[months[i]] ?? 0).toDouble(), color: PennyPalTheme.mint, width: 10, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: (expense[months[i]] ?? 0).toDouble(), color: PennyPalTheme.sky, width: 10, borderRadius: BorderRadius.circular(4)),
                ]),
            ],
          )),
        ),
      ),
      const SizedBox(height: 10),
      const Row(children: [Icon(Icons.circle, size: 9, color: PennyPalTheme.mint), SizedBox(width: 5), Text('Income', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), SizedBox(width: 14), Icon(Icons.circle, size: 9, color: PennyPalTheme.sky), SizedBox(width: 5), Text('Expenses', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
    ]));
  }
}
