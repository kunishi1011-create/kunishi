import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kunishi_expense/app.dart';

void main() {
  testWidgets('ログイン画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const KunishiExpenseApp());
    await tester.pumpAndSettle();

    expect(find.text('KUNISHI経費精算'), findsOneWidget);
    expect(find.text('ログイン'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
