import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/enums.dart';

/// ステータス表示。
/// アクセシビリティ配慮：色だけで判断させず、必ず「文字」＋「アイコン」を併記する。
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final ExpenseStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: dense ? 13 : 15, color: c),
          SizedBox(width: dense ? 4 : 5),
          // 文字による状態表示（必須）
          Text(
            status.label,
            style: TextStyle(
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
