import 'package:flutter_test/flutter_test.dart';
import 'package:kunishi_expense/data/mock_repository.dart';
import 'package:kunishi_expense/models/enums.dart';

void main() {
  // 回帰テスト：init() を呼ばずに signIn しても成功すること
  // （初期化順序に依存してログインが必ず失敗する不具合の再発防止）
  test('init() 未呼び出しでも signIn できる', () async {
    final repo = MockRepository();
    final user = await repo.signIn('employee@example.com', 'password');
    expect(user, isNotNull, reason: 'init前でもユーザーを解決できる必要がある');
    expect(user!.name, '山田 太郎');
  });

  test('init() 未呼び出しでも一覧を取得できる', () async {
    final repo = MockRepository();
    final list = await repo.fetchAllExpenses();
    expect(list, isNotEmpty);
  });

  test('テストユーザーでログインできる', () async {
    final repo = MockRepository();
    await repo.init();

    final emp = await repo.signIn('employee@example.com', 'password');
    expect(emp, isNotNull);
    expect(emp!.role, UserRole.employee);

    final admin = await repo.signIn('admin@example.com', 'password');
    expect(admin, isNotNull);
    expect(admin!.role, UserRole.admin);

    final bad = await repo.signIn('employee@example.com', 'wrong');
    expect(bad, isNull);
  });

  test('シードデータが要件を満たす', () async {
    final repo = MockRepository();
    await repo.init();
    final users = await repo.fetchUsers();
    final expenses = await repo.fetchAllExpenses();

    expect(users.length, greaterThanOrEqualTo(6));
    expect(expenses.length, greaterThanOrEqualTo(20));

    // 全ステータスが存在すること
    for (final s in ExpenseStatus.values) {
      expect(expenses.any((e) => e.status == s), isTrue,
          reason: '${s.label} のデータが存在しない');
    }
  });
}
