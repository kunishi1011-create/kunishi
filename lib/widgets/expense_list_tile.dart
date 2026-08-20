import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/expense.dart';
import 'status_chip.dart';

/// 申請一覧の1行。
/// showApplicant = true で申請者名を表示（管理者一覧用）
class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onTap,
    this.applicantName,
    this.highlight = false,
  });

  final Expense expense;
  final VoidCallback onTap;
  final String? applicantName;

  /// 承認待ちなど注目させたい行に左側のバーを付ける
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: highlight
              ? const Border(
                  left: BorderSide(
                      color: AppTheme.statusSubmitted, width: 4))
              : null,
        ),
        padding: EdgeInsets.only(
            left: highlight ? 10 : 14, right: 10, top: 12, bottom: 12),
        child: Row(
          children: [
            // 区分アイコン
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(e.category.icon,
                  size: 19, color: AppTheme.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (applicantName != null) ...[
                        Text(
                          applicantName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 11,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 7),
                          color: AppTheme.border,
                        ),
                      ],
                      Flexible(
                        child: Text(
                          e.category.label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSub,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    e.vendor,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '利用日 ${Fmt.date(e.expenseDate)}　申請 ${Fmt.date(e.submittedAt)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTheme.textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.yen(e.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                StatusChip(e.status, dense: true),
              ],
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppTheme.textSub),
          ],
        ),
      ),
    );
  }
}
