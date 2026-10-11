import 'package:flutter/material.dart';
import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class TransactionsScreen extends StatefulWidget {
  /// Changes whenever the Activity tab is opened so the list reloads.
  final int refreshSignal;
  const TransactionsScreen({super.key, this.refreshSignal = 0});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> data = [];
  bool loading = true;
  String type = 'ALL';
  String category = 'ALL';
  // 'ALL' or a month key such as 2026-10.
  String month = 'ALL';
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal > 0 && widget.refreshSignal != oldWidget.refreshSignal) load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final x = await PennyPalService.transactions();
      if (mounted) setState(() => data = x);
    } catch (_) {
      // Keep the previous list if the cloud is temporarily unavailable.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<String> get _months {
    final months = data.map((x) => '${x['date']}').where((d) => d.length >= 7).map((d) => d.substring(0, 7)).toSet().toList();
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final q = searchCtrl.text.trim().toLowerCase();
    final list = data.where((x) {
      final okType = type == 'ALL' || x['type'] == type;
      final cat = '${x['category_detail']?['name'] ?? ''}';
      final okCat = category == 'ALL' || cat == category;
      final okMonth = month == 'ALL' || '${x['date']}'.startsWith(month);
      final text = '${x['description']} $cat ${x['date']} ${x['amount']}'.toLowerCase();
      return okType && okCat && okMonth && (q.isEmpty || text.contains(q));
    }).toList();
    final months = _months;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(tooltip: 'Refresh', onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search description, category or amount',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(searchCtrl.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('All', type == 'ALL', () => setState(() => type = 'ALL')),
                _chip('Income', type == 'INCOME', () => setState(() => type = 'INCOME')),
                _chip('Expenses', type == 'EXPENSE', () => setState(() => type = 'EXPENSE')),
                ...PennyPalService.categories.map((c) => _chip(c, category == c, () => setState(() => category = category == c ? 'ALL' : c))),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.calendar_month_outlined, size: 18, color: PennyPalTheme.muted),
              const SizedBox(width: 8),
              const Text('Month', style: TextStyle(fontWeight: FontWeight.w700, color: PennyPalTheme.muted)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: month == 'ALL' || months.contains(month) ? month : 'ALL',
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('All months')),
                    ...months.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (v) => setState(() => month = v ?? 'ALL'),
                ),
              ),
              if (type != 'ALL' || category != 'ALL' || month != 'ALL' || q.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    type = 'ALL';
                    category = 'ALL';
                    month = 'ALL';
                    searchCtrl.clear();
                  }),
                  child: const Text('Clear filters'),
                ),
            ]),
            const SizedBox(height: 10),
            if (loading)
              const LoadingCard()
            else if (data.isEmpty)
              const EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet', message: 'Add an income or expense from the Overview screen and it will appear here.')
            else if (list.isEmpty)
              const EmptyState(icon: Icons.search_off_rounded, title: 'Nothing found', message: 'Try another search or filter.')
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Text('${list.length} transaction${list.length == 1 ? '' : 's'} • tap to edit or delete', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
              ),
              ...list.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MotionReveal(delay: Duration(milliseconds: 70 + (e.key < 10 ? e.key : 10) * 45), child: _TransactionCard(e.value, onChanged: load)),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), showCheckmark: false),
      );
}

class _TransactionCard extends StatelessWidget {
  final dynamic x;
  final Future<void> Function() onChanged;
  const _TransactionCard(this.x, {required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final income = x['type'] == 'INCOME';
    final amount = num.tryParse('${x['amount']}') ?? 0;
    final color = income ? PennyPalTheme.mint : PennyPalTheme.sky;
    final pending = x['pending_sync'] == true;
    final title = '${x['description']}'.isEmpty ? (income ? 'Income' : 'Untitled expense') : '${x['description']}';
    return Dismissible(
      key: ValueKey(x['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: PennyPalTheme.danger, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _delete(context),
      child: Semantics(
        button: true,
        label: '${income ? 'Income' : 'Expense'} $title, ${money(amount)}, ${x['category_detail']?['name'] ?? ''}, ${x['date']}. Tap to edit, long-press to delete.',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _edit(context),
          // Long-press is an alternative to swiping, which is hard to perform
          // with a mouse or with assistive technology.
          onLongPress: () async {
            if (await _confirmDelete(context) && context.mounted) _delete(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: AppCard(
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
                child: Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    '${x['category_detail']?['name'] ?? 'Miscellaneous'} • ${x['date']}${pending ? ' • waiting to sync' : ''}',
                    style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text('${income ? '+' : '-'}${money(amount)}', style: TextStyle(fontWeight: FontWeight.w900, color: income ? PennyPalTheme.mint : PennyPalTheme.danger)),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await PennyPalService.deleteTransaction('${x['id']}');
      messenger.showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not delete the transaction. Please try again.')));
    }
    afterNextFrame((_) => onChanged());
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This removes the record from your PennyPal history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _edit(BuildContext context) async {
    if (x['pending_sync'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This entry can be edited once it has synced.')));
      return;
    }
    final income = x['type'] == 'INCOME';
    final options = income ? PennyPalService.incomeSources : PennyPalService.categories;
    final amount = TextEditingController(text: '${x['amount']}');
    final desc = TextEditingController(text: '${x['description']}');
    final current = '${x['category_detail']?['name'] ?? ''}';
    String cat = options.contains(current) ? current : options.last;
    DateTime date = DateTime.tryParse('${x['date']}') ?? DateTime.now();
    String? error;
    bool busy = false;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          title: Text(income ? 'Edit income' : 'Edit expense'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦ ')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: cat,
                items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => cat = v ?? cat,
                decoration: InputDecoration(labelText: income ? 'Source' : 'Category'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_outlined),
                  label: Text('Date: ${PennyPalService.dateKey(date)}'),
                  onPressed: () async {
                    final picked = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime.now());
                    if (picked != null) setDialog(() => date = picked);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: desc, maxLength: 120, decoration: const InputDecoration(labelText: 'Description', counterText: '')),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: PennyPalTheme.danger, fontWeight: FontWeight.w700))),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!await _confirmDelete(c) || !c.mounted) return;
                      Navigator.pop(c);
                      if (context.mounted) await _delete(context);
                    },
              style: TextButton.styleFrom(foregroundColor: PennyPalTheme.danger),
              child: const Text('Delete'),
            ),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final a = double.tryParse(amount.text.replaceAll(',', '').trim());
                      if (a == null || a <= 0) {
                        setDialog(() => error = 'Enter an amount greater than zero.');
                        return;
                      }
                      setDialog(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await PennyPalService.updateTransaction('${x['id']}', {
                          'amount': a,
                          'category_name': cat,
                          'description': desc.text.trim(),
                          'date': PennyPalService.dateKey(date),
                        });
                        if (!c.mounted) return;
                        Navigator.pop(c);
                        afterNextFrame((_) {
                          if (context.mounted) onChanged();
                        });
                      } catch (_) {
                        setDialog(() {
                          busy = false;
                          error = 'Could not update the transaction. Please try again.';
                        });
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    desc.dispose();
  }
}
