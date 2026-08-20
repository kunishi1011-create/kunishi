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
class CenteredContent extends StatelessWidget {
  const CenteredContent({super.key, required this.child, this.maxWidth});
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: maxWidth ?? Responsive.contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}
