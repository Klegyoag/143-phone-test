import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});
  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  bool loading = true;
  List<Map<String, dynamic>> budgets = [], expenses = [];
  Map<String, dynamic> privacy = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final r = ref.read(relationshipToolsRepositoryProvider);
    try {
      final x =
          await Future.wait([r.budgets(), r.expenses(), r.budgetPrivacy()]);
      budgets = x[0] as List<Map<String, dynamic>>;
      expenses = x[1] as List<Map<String, dynamic>>;
      privacy = x[2] as Map<String, dynamic>;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addBudget() async {
    final title = TextEditingController(), amount = TextEditingController();
    String type = 'date';
    final ok = await showDialog<bool>(
        context: context,
        builder: (x) => StatefulBuilder(
            builder: (x, setD) => AlertDialog(
                    title: const Text('New shared budget'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: title,
                          decoration: const InputDecoration(labelText: 'Name')),
                      const SizedBox(height: 10),
                      TextField(
                          controller: amount,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Amount (LKR)')),
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                          value: type,
                          items: const [
                            DropdownMenuItem(
                                value: 'date', child: Text('Date')),
                            DropdownMenuItem(value: 'trip', child: Text('Trip'))
                          ],
                          onChanged: (v) => setD(() => type = v!),
                          decoration: const InputDecoration(labelText: 'Type'))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(x, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(x, true),
                          child: const Text('Create'))
                    ])));
    if (ok == true) {
      await ref.read(relationshipToolsRepositoryProvider).createBudget({
        'title': title.text.trim(),
        'name': title.text.trim(),
        'amount': double.tryParse(amount.text) ?? 0,
        'type': type
      });
      _load();
    }
  }

  Future<void> _addExpense() async {
    final title = TextEditingController(), amount = TextEditingController();
    String category = 'date';
    final ok = await showDialog<bool>(
        context: context,
        builder: (x) => AlertDialog(
                title: const Text('Add expense'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: title,
                      decoration:
                          const InputDecoration(labelText: 'What was it?')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Amount (LKR)'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(x, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(x, true),
                      child: const Text('Add'))
                ]));
    if (ok == true) {
      await ref.read(relationshipToolsRepositoryProvider).createExpense({
        'title': title.text.trim(),
        'amount': double.tryParse(amount.text) ?? 0,
        'category': category
      });
      _load();
    }
  }

  Future<void> _privacy(bool v) async {
    await ref.read(relationshipToolsRepositoryProvider).updateBudgetPrivacy(
        {'visible_to_partner': v, 'share_totals': v, 'share_item_details': v});
    _load();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Optional Couple Budget')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: AppColors.softSurface(c),
                            borderRadius: BorderRadius.circular(26)),
                        child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  color: AppColors.rose),
                              SizedBox(height: 8),
                              Text('Planning, not accounting.',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18)),
                              Text(
                                  'Keep trip/date money simple and secondary to your shared life.',
                                  style: TextStyle(color: AppColors.muted))
                            ])),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visible to partner'),
                        subtitle:
                            const Text('You can keep this module private.'),
                        value: privacy['visible_to_partner'] != false,
                        onChanged: _privacy),
                    Row(children: [
                      Expanded(
                          child: FilledButton.icon(
                              onPressed: _addBudget,
                              icon: const Icon(Icons.add),
                              label: const Text('Budget'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: _addExpense,
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Expense')))
                    ]),
                    const SizedBox(height: 20),
                    const Text('Budgets',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    if (budgets.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No date or trip budget yet.'))
                    else
                      ...budgets.map(_budget),
                    const SizedBox(height: 20),
                    const Text('Expense log',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    if (expenses.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No shared expenses yet.'))
                    else
                      ...expenses.map(_expense)
                  ])));
  Widget _budget(Map<String, dynamic> x) {
    final d = x['data'] is Map ? (x['data'] as Map) : x;
    return Card(
        child: ListTile(
            leading: const CircleAvatar(
                backgroundColor: AppColors.blush,
                child: Icon(Icons.savings_outlined, color: AppColors.rose)),
            title: Text('${x['title'] ?? d['name'] ?? 'Our budget'}'),
            subtitle: Text('${d['type'] ?? ''} • LKR ${d['amount'] ?? '—'}')));
  }

  Widget _expense(Map<String, dynamic> x) {
    final d = x['data'] is Map ? (x['data'] as Map) : x;
    return Card(
        child: ListTile(
      leading: const Icon(Icons.receipt_outlined, color: AppColors.rose),
      title: Text('${x['title'] ?? d['title'] ?? 'Expense'}'),
      subtitle: Text(
          '${d['category'] ?? ''}${x['status'] == 'split' ? ' • split recorded' : ''}'),
      trailing: PopupMenuButton<String>(
        tooltip: 'Expense actions',
        onSelected: (v) async {
          if (v == 'split') {
            await ref
                .read(relationshipToolsRepositoryProvider)
                .splitExpense('${x['id']}', {'strategy': 'equal', 'shares': 2});
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Equal split recorded for the two of you.')));
            _load();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
              enabled: false,
              child: Text('LKR ${d['amount'] ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          const PopupMenuItem(
              value: 'split',
              child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.call_split_rounded),
                  title: Text('Split equally'))),
        ],
      ),
    ));
  }
}
