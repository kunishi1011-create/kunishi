import 'package:flutter/material.dart';
import '../models/enums.dart';

/// 業務アプリ向け：落ち着いた配色・高い可読性・押しやすいボタンサイズ
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1F4E79); // 落ち着いた紺
  static const Color primaryLight = Color(0xFFE8EEF5);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color border = Color(0xFFD8DDE4);
  static const Color textMain = Color(0xFF1A1D21);
  static const Color textSub = Color(0xFF5C6672);

  // ステータス色（文字表示と必ず併用する）
  static const Color statusDraft = Color(0xFF6B7280);
  static const Color statusSubmitted = Color(0xFFB45309);
  static const Color statusApproved = Color(0xFF15803D);
  static const Color statusReturned = Color(0xFFB91C1C);
  static const Color statusSettled = Color(0xFF1D4ED8);

  static Color statusColor(ExpenseStatus s) {
    switch (s) {
      case ExpenseStatus.draft:
        return statusDraft;
      case ExpenseStatus.submitted:
        return statusSubmitted;
      case ExpenseStatus.approved:
        return statusApproved;
      case ExpenseStatus.returned:
        return statusReturned;
      case ExpenseStatus.settled:
        return statusSettled;
    }
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      // 業務アプリのため文字は大きめ・行間広め
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: textMain),
        titleLarge: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w700, color: textMain),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: textMain),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: textMain),
        bodyMedium: TextStyle(fontSize: 14.5, height: 1.5, color: textMain),
        bodySmall: TextStyle(fontSize: 13, height: 1.4, color: textSub),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        // スマホで押しやすい十分な高さ
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: statusReturned, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 15, color: textSub),
        floatingLabelStyle: const TextStyle(fontSize: 14, color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          // 誤操作しにくい十分なタップ領域（高さ52）
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: border),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryLight,
        height: 68,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textMain,
        contentTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
