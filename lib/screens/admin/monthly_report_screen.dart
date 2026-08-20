import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../providers/expense_provider.dart';

/// 管理者向け 月次集計
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  String? _monthKey;

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final months = ep.availableMonthKeys;
    final selected = _monthKey ??
        (months.contains(ep.currentMonthKey)
            ? ep.currentMonthKey
            : (months.isNotEmpty ? months.first : ep.currentMonthKey));
    final s = ep.summary(monthKey: selected);
    final maxCat = s.byCategory.values.isEmpty
        ? 1
        : s.byCategory.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: CenteredContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('月次集計',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            const Text('全社の経費申請状況を月ごとに集計します',
                style: TextStyle(fontSize: 13.5, color: AppTheme.textSub)),
            const SizedBox(height: 16),

            // 対象月の選択
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('対象月',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSub)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      items: (months.isEmpty ? [selected] : months)
                          .map((k) => DropdownMenuItem(
                              value: k,
                              child: Text(Fmt.monthKeyLabel(k),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700))))
                          .toList(),
                      onChanged: (v) => setState(() => _monthKey = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ===== 金額サマリー（表形式で一覧性重視） =====
            const _SectionTitle('金額サマリー'),
            const SizedBox(height: 9),
            Card(
              child: Column(
                children: [
                  _SummaryRow(
                    label: '月間申請総額',
                    amount: s.total,
                    count: s.totalCount,
                    color: AppTheme.primary,
                    emphasize: true,
                  ),
                  const Divider(height: 1),
                  _SummaryRow(
                    label: '承認済み金額',
                    amount: s.approved + s.settled,
                    color: AppTheme.statusApproved,
                    note: '精算済みを含む',
                  ),
                  const Divider(height: 1),
                  _SummaryRow(
                    label: '未承認金額',
                    amount: s.unapproved,
                    color: AppTheme.statusSubmitted,
                    note: '申請中 ${Fmt.yen(s.pending)} / 差し戻し ${Fmt.yen(s.returned)}',
                  ),
                  const Divider(height: 1),
                  _SummaryRow(
                    label: '精算済み金額',
                    amount: s.settled,
                    color: AppTheme.statusSettled,
                    note: '支払完了',
                  ),
                  const Divider(height: 1),
                  _SummaryRow(
                    label: '未精算金額',
                    amount: s.unsettled,
                    color: AppTheme.statusReturned,
                    note: '承認済み・支払前',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== 経費区分別 =====
            const _SectionTitle('経費区分別の金額'),
            const SizedBox(height: 9),
            Card(
              child: s.byCategory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 34),
                      child: Center(
                        child: Text('この月の申請データはありません',
                            style: TextStyle(
                                fontSize: 14, color: AppTheme.textSub)),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (final entry in s.byCategory.entries) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(entry.key.icon,
                                          size: 17,
                                          color: AppTheme.primary),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(entry.key.label,
                                            style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                      Text(Fmt.yen(entry.value),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color:
                                                  AppTheme.textMain)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // 簡易バーグラフ
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: entry.value / maxCat,
                                      minHeight: 8,
                                      backgroundColor: AppTheme.surface,
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                              AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    s.total > 0
                                        ? '全体の ${(entry.value / s.total * 100).toStringAsFixed(1)}%'
                                        : '—',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textSub),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text('合計',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Text(Fmt.yen(s.total),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain));
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    this.count,
    this.note,
    this.emphasize = false,
    this.isLast = false,
  });

  final String label;
  final int amount;
  final Color color;
  final int? count;
  final String? note;
  final bool emphasize;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: emphasize ? AppTheme.primaryLight : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: emphasize ? 15 : 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain)),
                if (note != null || count != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    count != null ? '$count件　${note ?? ''}' : note!,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTheme.textSub),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Fmt.yen(amount),
            style: TextStyle(
                fontSize: emphasize ? 21 : 17,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}
