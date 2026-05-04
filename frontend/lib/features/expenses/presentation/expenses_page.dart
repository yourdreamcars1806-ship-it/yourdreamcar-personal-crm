import 'package:flutter/material.dart';

import '../../../core/theme/brand_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/expense_service.dart';
import '../data/expense_store.dart';
import '../domain/expense_entry.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => ExpensesPageState();
}

class ExpensesPageState extends State<ExpensesPage> {
  final _api = ExpenseService();
  final _legacyStore = ExpenseStore();
  final _entries = <ExpenseEntry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads from MongoDB via API (same account after re-login). Migrates old local data once.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      var list = await _api.fetchExpenses(limit: 500);
      if (list.isEmpty) {
        final local = await _legacyStore.load();
        if (local.isNotEmpty) {
          for (final e in local) {
            await _api.createExpense(title: e.title, amount: e.amount);
          }
          await _legacyStore.save([]);
          list = await _api.fetchExpenses(limit: 500);
        }
      }
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(context, e.toString());
    }
  }

  Future<void> openAddExpenseDialog() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F2442),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Color(0xFF16345E)),
                decoration: _fieldDecoration('Title (fuel, service, toll...)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Color(0xFF16345E)),
                decoration: _fieldDecoration('Amount'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (title.isEmpty || amount == null || amount <= 0) {
                    AppToast.error(ctx, 'Enter valid title and amount');
                    return;
                  }
                  try {
                    final entry = await _api.createExpense(
                      title: title,
                      amount: amount,
                    );
                    if (!ctx.mounted || !mounted) return;
                    setState(() => _entries.insert(0, entry));
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    AppToast.success(context, 'Expense added successfully');
                  } catch (e) {
                    if (!ctx.mounted) return;
                    AppToast.error(ctx, e.toString());
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D63ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditExpenseDialog(ExpenseEntry entry) async {
    final titleCtrl = TextEditingController(text: entry.title);
    final amountCtrl = TextEditingController(
      text: entry.amount.toStringAsFixed(0),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2442),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Color(0xFF16345E)),
                decoration: _fieldDecoration('Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Color(0xFF16345E)),
                decoration: _fieldDecoration('Amount'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (title.isEmpty || amount == null || amount <= 0) {
                    AppToast.error(ctx, 'Enter valid title and amount');
                    return;
                  }
                  try {
                    final updated = await _api.updateExpense(
                      id: entry.id,
                      title: title,
                      amount: amount,
                    );
                    if (!mounted || !ctx.mounted) return;
                    setState(() {
                      final idx = _entries.indexWhere((e) => e.id == entry.id);
                      if (idx != -1) _entries[idx] = updated;
                    });
                    Navigator.pop(ctx);
                    AppToast.success(context, 'Expense updated successfully');
                  } catch (e) {
                    if (!ctx.mounted) return;
                    AppToast.error(ctx, e.toString());
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D63ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Update Expense',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteExpense(ExpenseEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${entry.title}" from your expense history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE07771),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.deleteExpense(entry.id);
      if (!mounted) return;
      setState(() => _entries.removeWhere((e) => e.id == entry.id));
      AppToast.success(context, 'Expense deleted successfully');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7A93B7)),
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E5FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E5FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D63ED)),
      ),
    );
  }

  double get _total => _entries.fold(0.0, (sum, e) => sum + e.amount);

  double get _daily {
    final now = DateTime.now();
    return _entries
        .where(
          (e) =>
              e.createdAt.year == now.year &&
              e.createdAt.month == now.month &&
              e.createdAt.day == now.day,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _monthly {
    final now = DateTime.now();
    return _entries
        .where(
          (e) => e.createdAt.year == now.year && e.createdAt.month == now.month,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  String _dateTimeText(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final day = two(dt.day);
    final month = two(dt.month);
    final year = dt.year;
    final hour24 = dt.hour;
    final minute = two(dt.minute);
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$day/$month/$year  $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF162138) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF);
    final titleColor = isDark ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442);
    final mutedColor = isDark ? const Color(0xFF9DB0CC) : const Color(0xFF5B769E);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0E1320), Color(0xFF131C2E), Color(0xFF172339)]
              : const [Color(0xFFF7FAFF), Color(0xFFF2F7FF), Color(0xFFEAF2FF)],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: Color(0xFF1D63ED),
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [Color(0xFF162138), Color(0xFF1A2942)]
                            : const [Colors.white, Color(0xFFF4F8FF)],
                      ),
                      border: Border.all(color: borderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0A3A7A),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'My expenses',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: titleColor,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: openAddExpenseDialog,
                          icon: const Icon(Icons.add_rounded),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0x1F1D63ED),
                            foregroundColor: const Color(0xFF1D63ED),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          label: const Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF162138), Color(0xFF1A2942)]
                            : [Colors.white, const Color(0xFFF4F8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0x1F1D63ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF1D63ED),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total expenses',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _money(_total),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFE6EEFF)
                                      : const Color(0xFF173A64),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _SummaryGrid(
                    values: [
                      _SummaryItemData(label: 'Today', value: _money(_daily)),
                      _SummaryItemData(
                        label: 'Monthly',
                        value: _money(_monthly),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Text(
                    'Expense history',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFE6EEFF)
                          : const Color(0xFF173A64),
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No expense yet.\nTap Add to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  sliver: SliverList.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x120A3A7A),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0x1F1D63ED),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF1D63ED),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFE6EEFF)
                                          : const Color(0xFF16345E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _dateTimeText(e.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1F1D63ED),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _money(e.amount),
                                    style: const TextStyle(
                                      color: Color(0xFF1D63ED),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () => _openEditExpenseDialog(e),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: Color(0xFF355F9A),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteExpense(e),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Color(0xFFE07771),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItemData {
  const _SummaryItemData({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.values});

  final List<_SummaryItemData> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: values
              .map(
                (e) => SizedBox(
                  width: itemWidth,
                  child: _SummaryCard(label: e.label, value: e.value),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162138) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFE6EEFF) : const Color(0xFF173A64),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF9DB0CC)
                  : BrandColors.muted.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
