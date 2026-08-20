import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/expense_repository.dart';
import 'data/mock_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';

class KunishiExpenseApp extends StatelessWidget {
  const KunishiExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ★差し替え点：STEP2 で HiveRepository / FirestoreRepository に変更
    final ExpenseRepository repo = MockRepository();

    return MultiProvider(
      providers: [
        Provider<ExpenseRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => AuthProvider(repo)),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(repo)),
      ],
      child: MaterialApp(
        title: 'KUNISHI経費精算',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ja'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
        initialRoute: LoginScreen.route,
        routes: {
          LoginScreen.route: (_) => const LoginScreen(),
          ShellScreen.route: (_) => const ShellScreen(),
        },
      ),
    );
  }
}
