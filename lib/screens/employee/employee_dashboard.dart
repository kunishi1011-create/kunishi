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
import 'expense_form_screen.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key, required this.onNavigateToList});
  final VoidCallback onNavigateToList;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ep = context.watch<ExpenseProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final monthKey = ep.currentMonthKey;
    final s = ep.summary(userId: user.id, monthKey: monthKey);
    final recent = ep.forUser(user.id).take(5).toList();

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: CenteredContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 挨拶
            Text('お疲れさまです、${user.name} さん',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text('${user.department}　|　${Fmt.monthKeyLabel(monthKey)}の状況',
                style: const TextStyle(
                    fontSize: 13.5, color: AppTheme.textSub)),
            const SizedBox(height: 16),

            // 新規申請ボタン（最も使う操作なので目立たせる）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ExpenseFormScreen()),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text('新規経費申請'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 56)),
              ),
            ),
            const SizedBox(height: 18),

            const _SectionTitle('今月のサマリー'),
            const SizedBox(height: 10),
            StatGrid(
              columns: Responsive.statColumns(context),
              children: [
                StatCard(
                  label: '今月の申請金額',
                  value: Fmt.yen(s.total),
                  subLabel: '${s.totalCount}件',
                  icon: Icons.summarize_outlined,
                  accent: AppTheme.primary,
                ),
                StatCard(
                  label: '承認待ち金額',
                  value: Fmt.yen(s.pending),
                  subLabel: '${s.pendingCount}件が申請中',
                  icon: Icons.schedule,
                  accent: AppTheme.statusSubmitted,
                ),
                StatCard(
                  label: '承認済み金額',
                  value: Fmt.yen(s.approved),
                  subLabel: '精算待ち',
                  icon: Icons.check_circle_outline,
                  accent: AppTheme.statusApproved,
                ),
                StatCard(
                  label: '精算済み金額',
                  value: Fmt.yen(s.settled),
                  subLabel: '支払完了',
                  icon: Icons.paid,
                  accent: AppTheme.statusSettled,
                ),
              ],
            ),

            // 差し戻しがある場合の注意喚起
            if (s.returned > 0) ...[
              const SizedBox(height: 14),
              _AlertBanner(
                icon: Icons.undo,
                color: AppTheme.statusReturned,
                title: '差し戻された申請があります',
                message:
                    '${Fmt.yen(s.returned)} 分の申請が差し戻されています。内容を修正して再申請してください。',
                actionLabel: '確認する',
                onAction: onNavigateToList,
              ),
            ],

            const SizedBox(height: 22),

            // 最近の申請
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
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 34, color: AppTheme.textSub),
                            SizedBox(height: 8),
                            Text('申請はまだありません',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSub)),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < recent.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ExpenseListTile(
                            expense: recent[i],
                            highlight: recent[i].status ==
                                ExpenseStatus.returned,
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

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontSize: 13.5, color: AppTheme.textMain, height: 1.45)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: color),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
