import 'package:flutter/material.dart';
import '../core/theme.dart';

/// ダッシュボード用の数値カード
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subLabel,
    this.icon,
    this.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subLabel;
  final IconData? icon;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppTheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(icon, size: 16, color: c),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSub,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c,
                    height: 1.1,
                  ),
                ),
              ),
              if (subLabel != null) ...[
                const SizedBox(height: 3),
                Text(
                  subLabel!,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSub),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 統計カードを画面幅に応じてグリッド配置
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, required this.columns});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((c) => SizedBox(width: w, height: 118, child: c))
              .toList(),
        );
      },
    );
  }
}
