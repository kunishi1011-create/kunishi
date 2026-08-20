import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expense_list_tile.dart';
import '../../widgets/filter_bar.dart';
import '../expense_detail_screen.dart';
import 'expense_form_screen.dart';

/// 一般社員：自分の申請一覧（月 / ステータス / 経費区分で絞り込み）
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String? _monthKey;
  ExpenseStatus? _status;
  ExpenseCategory? _category;

  bool get _hasFilter =>
      _monthKey != null || _status != null || _category != null;

  void _reset() => setState(() {
        _monthKey = null;
        _status = null;
        _category = null;
      });

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final list = ep.filter(
      userId: user.id,
      monthKey: _monthKey,
      status: _status,
      category: _category,
    );
    final total = list.fold<int>(0, (p, e) => p + e.amount);

    return Column(
      children: [
        // 絞り込み
        FilterBar(
          hasActiveFilter: _hasFilter,
          onReset: _reset,
          children: [
            FilterDropdown<String>(
              label: '月',
              value: _monthKey,
              allLabel: '全期間',
              width: 140,
              items: ep.availableMonthKeys
                  .map((k) => DropdownMenuItem<String?>(
                      value: k, child: Text(Fmt.monthKeyLabel(k))))
                  .toList(),
              onChanged: (v) => setState(() => _monthKey = v),
            ),
            FilterDropdown<ExpenseStatus>(
              label: 'ステータス',
              value: _status,
              width: 150,
              items: ExpenseStatus.values
                  .map((s) => DropdownMenuItem<ExpenseStatus?>(
                      value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v),
            ),
            FilterDropdown<ExpenseCategory>(
              label: '経費区分',
              value: _category,
              width: 150,
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem<ExpenseCategory?>(
                      value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
          ],
        ),
        const Divider(height: 1),

        // 件数・合計
        Container(
          width: double.infinity,
          color: AppTheme.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: CenteredContent(
            child: Row(
              children: [
                Text('${list.length}件',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                const SizedBox(width: 12),
                Text('合計 ${Fmt.yen(total)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
              ],
            ),
          ),
        ),

        // 一覧
        Expanded(
          child: list.isEmpty
              ? _EmptyState(hasFilter: _hasFilter, onReset: _reset)
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = list[i];
                    return Container(
                      color: Colors.white,
                      child: CenteredContent(
                        child: ExpenseListTile(
                          expense: e,
                          highlight: e.status == ExpenseStatus.returned,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseDetailScreen(expenseId: e.id),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter, required this.onReset});
  final bool hasFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 46, color: AppTheme.textSub),
            const SizedBox(height: 12),
            Text(
              hasFilter ? '条件に合う申請がありません' : '申請はまだありません',
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSub),
            ),
            const SizedBox(height: 16),
            if (hasFilter)
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('絞り込みを解除'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ExpenseFormScreen()),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('新規経費申請'),
              ),
          ],
        ),
      ),
    );
  }
}
