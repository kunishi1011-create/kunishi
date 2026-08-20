import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expense_list_tile.dart';
import '../../widgets/stat_card.dart';
import '../expense_detail_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({
    super.key,
    required this.onNavigateToList,
    required this.onNavigateToReport,
  });

  final VoidCallback onNavigateToList;
  final VoidCallback onNavigateToReport;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ep = context.watch<ExpenseProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final monthKey = ep.currentMonthKey;
    final s = ep.summary(monthKey: monthKey);

    // 承認待ちを優先表示
    final pendingList = ep.allExpenses
        .where((e) => e.status == ExpenseStatus.submitted)
        .toList();
    final recent = ep.allExpenses
        .where((e) => e.status != ExpenseStatus.draft)
        .take(6)
        .toList();

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: CenteredContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('管理者ダッシュボード',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text('${user.name}（${user.department}）　|　${Fmt.monthKeyLabel(monthKey)}',
                style: const TextStyle(
                    fontSize: 13.5, color: AppTheme.textSub)),
            const SizedBox(height: 16),

            // 承認待ちの通知バナー（最優先の業務）
            if (s.pendingCount > 0)
              InkWell(
                onTap: onNavigateToList,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSubmitted.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.statusSubmitted
                            .withValues(alpha: 0.5),
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.statusSubmitted,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.pending_actions,
                            color: Colors.white, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('承認待ち ${pendingList.length}件',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.statusSubmitted)),
                            const SizedBox(height: 2),
                            Text('合計 ${Fmt.yen(s.pending)}　確認をお願いします',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textMain)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppTheme.statusSubmitted),
                    ],
                  ),
                ),
              ),
            if (s.pendingCount > 0) const SizedBox(height: 18),

            const _SectionTitle('今月の全社サマリー'),
            const SizedBox(height: 10),
            StatGrid(
              columns: Responsive.statColumns(context),
              children: [
                StatCard(
                  label: '今月の申請総額',
                  value: Fmt.yen(s.total),
                  subLabel: '${s.totalCount}件',
                  icon: Icons.summarize_outlined,
                  accent: AppTheme.primary,
                ),
                StatCard(
                  label: '承認待ち件数',
                  value: '${s.pendingCount}件',
                  subLabel: '要対応',
                  icon: Icons.pending_actions,
                  accent: AppTheme.statusSubmitted,
                  onTap: onNavigateToList,
                ),
                StatCard(
                  label: '承認待ち金額',
                  value: Fmt.yen(s.pending),
                  subLabel: '未承認',
                  icon: Icons.schedule,
                  accent: AppTheme.statusSubmitted,
                ),
                StatCard(
                  label: '承認済み金額',
                  value: Fmt.yen(s.approved + s.settled),
                  subLabel: '精算済みを含む',
                  icon: Icons.check_circle_outline,
                  accent: AppTheme.statusApproved,
                ),
                StatCard(
                  label: '未精算金額',
                  value: Fmt.yen(s.unsettled),
                  subLabel: '承認済み・支払前',
                  icon: Icons.account_balance_wallet_outlined,
                  accent: AppTheme.statusReturned,
                ),
                StatCard(
                  label: '精算済み金額',
                  value: Fmt.yen(s.settled),
                  subLabel: '支払完了',
                  icon: Icons.paid,
                  accent: AppTheme.statusSettled,
                  onTap: onNavigateToReport,
                ),
              ],
            ),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle('最近の申請'),
                TextButton(
                  onPressed: onNavigateToList,
                  child: const Text('すべて見る'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Card(
              child: recent.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 34),
                      child: Center(
                        child: Text('申請はまだありません',
                            style: TextStyle(
                                fontSize: 14, color: AppTheme.textSub)),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < recent.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ExpenseListTile(
                            expense: recent[i],
                            applicantName: ep.userName(recent[i].userId),
                            highlight: recent[i].status ==
                                ExpenseStatus.submitted,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExpenseDetailScreen(
                                    expenseId: recent[i].id),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNavigateToReport,
                icon: const Icon(Icons.bar_chart, size: 20),
                label: const Text('月次集計を見る'),
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
