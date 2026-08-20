import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 絞り込み用の小さなドロップダウン。
/// 入力項目を詰め込みすぎないよう、横スクロールで並べる。
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.allLabel = 'すべて',
    this.width = 150,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?> onChanged;
  final String allLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          filled: true,
          fillColor: active ? AppTheme.primaryLight : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
                color: active ? AppTheme.primary : AppTheme.border,
                width: active ? 1.5 : 1),
          ),
          labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSub),
        ),
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// フィルタ行（横スクロール）
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.children,
    this.onReset,
    this.hasActiveFilter = false,
  });

  final List<Widget> children;
  final VoidCallback? onReset;
  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // ラベルが上端で欠けないよう上側の余白を確保する
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in children) ...[c, const SizedBox(width: 8)],
            if (hasActiveFilter && onReset != null)
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('条件クリア'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    side: const BorderSide(color: AppTheme.border),
                    foregroundColor: AppTheme.textSub,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
