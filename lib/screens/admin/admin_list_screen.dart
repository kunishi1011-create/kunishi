import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expense_list_tile.dart';
import '../../widgets/filter_bar.dart';
import '../expense_detail_screen.dart';

/// 管理者：全社員の申請一覧
/// 「承認待ち」がすぐ分かるよう、上部にタブ（承認待ち / すべて）を配置
class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key, this.initialPendingOnly = true});
  final bool initialPendingOnly;

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  late bool _pendingOnly;
  String? _monthKey;
  String? _userId;
  ExpenseStatus? _status;
  ExpenseCategory? _category;

  @override
  void initState() {
    super.initState();
    _pendingOnly = widget.initialPendingOnly;
  }

  bool get _hasFilter =>
      _monthKey != null ||
      _userId != null ||
      _status != null ||
      _category != null;

  void _reset() => setState(() {
        _monthKey = null;
        _userId = null;
        _status = null;
        _category = null;
      });

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();

    List<Expense> list = ep.filter(
      userId: _userId,
      monthKey: _monthKey,
      status: _status,
      category: _category,
    );
    // 下書きは他人には見せない（本人のみ扱い）
    list = list.where((e) => e.status != ExpenseStatus.draft).toList();

    final pendingCount = ep.allExpenses
        .where((e) => e.status == ExpenseStatus.submitted)
        .length;

    if (_pendingOnly) {
      list = list.where((e) => e.status == ExpenseStatus.submitted).toList();
    }
    final total = list.fold<int>(0, (p, e) => p + e.amount);

    return Column(
      children: [
        // 承認待ち / すべて の切替
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: CenteredContent(
            child: Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: '承認待ち',
                    count: pendingCount,
                    selected: _pendingOnly,
                    accent: AppTheme.statusSubmitted,
                    onTap: () => setState(() => _pendingOnly = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleButton(
                    label: 'すべての申請',
                    selected: !_pendingOnly,
                    accent: AppTheme.primary,
                    onTap: () => setState(() => _pendingOnly = false),
                  ),
                ),
              ],
            ),
          ),
        ),

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
            FilterDropdown<String>(
              label: '社員',
              value: _userId,
              allLabel: '全社員',
              width: 150,
              items: ep.employees
                  .map((u) => DropdownMenuItem<String?>(
                      value: u.id, child: Text(u.name)))
                  .toList(),
              onChanged: (v) => setState(() => _userId = v),
            ),
            if (!_pendingOnly)
              FilterDropdown<ExpenseStatus>(
                label: 'ステータス',
                value: _status,
                width: 150,
                items: ExpenseStatus.values
                    .where((s) => s != ExpenseStatus.draft)
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
          color: _pendingOnly
              ? AppTheme.statusSubmitted.withValues(alpha: 0.09)
              : AppTheme.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: CenteredContent(
            child: Row(
              children: [
                Icon(
                    _pendingOnly
                        ? Icons.pending_actions
                        : Icons.list_alt,
                    size: 16,
                    color: _pendingOnly
                        ? AppTheme.statusSubmitted
                        : AppTheme.primary),
                const SizedBox(width: 6),
                Text('${list.length}件',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _pendingOnly
                            ? AppTheme.statusSubmitted
                            : AppTheme.primary)),
                const SizedBox(width: 12),
                Text('合計 ${Fmt.yen(total)}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _pendingOnly
                            ? AppTheme.statusSubmitted
                            : AppTheme.primary)),
              ],
            ),
          ),
        ),

        // 一覧
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _pendingOnly
                                ? Icons.check_circle_outline
                                : Icons.search_off,
                            size: 46,
                            color: _pendingOnly
                                ? AppTheme.statusApproved
                                : AppTheme.textSub),
                        const SizedBox(height: 12),
                        Text(
                          _pendingOnly
                              ? '承認待ちの申請はありません'
                              : '条件に合う申請がありません',
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: _pendingOnly
                                  ? AppTheme.statusApproved
                                  : AppTheme.textSub),
                        ),
                        if (_hasFilter) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('絞り込みを解除'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
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
                          applicantName: ep.userName(e.userId),
                          highlight: e.status == ExpenseStatus.submitted,
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

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: selected ? accent : AppTheme.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSub,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
