import 'package:flutter/material.dart';

/// 画面幅によるレイアウト切替
/// mobile  : ~ 700   (iPhone / Android)
/// tablet  : 700 ~ 1100 (タブレット)
/// desktop : 1100 ~   (PC)
class Responsive {
  Responsive._();

  static const double mobileMax = 700;
  static const double tabletMax = 1100;

  static bool isMobile(BuildContext c) =>
      MediaQuery.sizeOf(c).width < mobileMax;

  static bool isTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= tabletMax;

  /// PCでは中央に寄せて読みやすい幅に制限
  static double contentMaxWidth(BuildContext c) =>
      isDesktop(c) ? 1180 : double.infinity;

  /// 統計カードの列数
  static int statColumns(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w < 480) return 2;
    if (w < mobileMax) return 2;
    if (w < tabletMax) return 3;
    return 4;
  }

  static EdgeInsets pagePadding(BuildContext c) => EdgeInsets.symmetric(
        horizontal: isMobile(c) ? 14 : 24,
        vertical: isMobile(c) ? 14 : 20,
      );
}

/// PCで中央寄せするラッパー
///
/// ⚠️ 重要（不具合の再発防止）:
/// 素の [Center] は縦方向の制約が「有界（maxHeightが有限）」な場所に置くと
/// 中身の高さに関係なく maxHeight まで広がってしまう。
/// これを Scaffold の bottomNavigationBar の中で使うと、
/// bottom bar が画面全高を占有し body の高さが 0 になり、
/// body 側の ListView / SingleChildScrollView は
/// 「例外を出さずに子を1つも build しない」＝白画面になる。
///
/// そのため既定では縦方向に広がらない（[heightFactor] = 1.0）挙動とし、
/// 縦いっぱいに使いたい画面のみ `expand: true` を明示する。
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.expand = false,
  });

  final Widget child;
  final double? maxWidth;

  /// true の場合のみ縦方向にも最大まで広がる。
  /// bottomNavigationBar / Column の中などでは必ず false のままにする。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final constrained = ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.contentMaxWidth(context)),
      child: child,
    );

    // heightFactor: 1.0 → 高さは常に子のサイズに一致する（広がらない）
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: expand ? null : 1.0,
      child: constrained,
    );
  }
}
