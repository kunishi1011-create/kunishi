import '../models/app_user.dart';
import '../models/expense.dart';
import 'expense_repository.dart';
import 'seed_data.dart';

/// STEP1用：メモリ上でダミーデータを扱う実装。
/// STEP2 で HiveRepository / FirestoreRepository に差し替える。
class MockRepository implements ExpenseRepository {
  final List<AppUser> _users = [];
  final List<Expense> _expenses = [];
  int _seq = 100;

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _users.addAll(SeedData.users());
    _expenses.addAll(SeedData.expenses());
  }

  /// 初期化順序に依存しないためのガード。
  /// どのメソッドから最初に呼ばれても安全に動作する。
  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  // ---- users ----
  @override
  Future<List<AppUser>> fetchUsers() async {
    await _ensureInit();
    return List.unmodifiable(_users);
  }

  @override
  Future<AppUser?> findUserByEmail(String email) async {
    await _ensureInit();
    final e = email.trim().toLowerCase();
    for (final u in _users) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  @override
  Future<AppUser?> signIn(String email, String password) async {
    await _ensureInit();
    // プロトタイプ用の簡易認証。STEP2 で Firebase Auth 等に差し替える。
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final user = await findUserByEmail(email);
    if (user == null) return null;
    if (password.trim() != SeedData.testPassword) return null;
    return user;
  }

  // ---- expenses ----
  @override
  Future<List<Expense>> fetchAllExpenses() async {
    await _ensureInit();
    return List.unmodifiable(_expenses);
  }

  @override
  Future<List<Expense>> fetchExpensesByUser(String userId) async {
    await _ensureInit();
    return _expenses.where((e) => e.userId == userId).toList();
  }

  @override
  Future<Expense?> findExpense(String id) async {
    await _ensureInit();
    for (final e in _expenses) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<Expense> createExpense(Expense expense) async {
    await _ensureInit();
    final withId = expense.id.isEmpty
        ? Expense.fromMap({
            ...expense.toMap(),
            'id': 'ex_${(++_seq).toString().padLeft(3, '0')}',
          })
        : expense;
    _expenses.add(withId);
    return withId;
  }

  @override
  Future<Expense> updateExpense(Expense expense) async {
    await _ensureInit();
    final i = _expenses.indexWhere((e) => e.id == expense.id);
    if (i >= 0) {
      _expenses[i] = expense;
    } else {
      _expenses.add(expense);
    }
    return expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _ensureInit();
    _expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> resetToSeed() async {
    _users
      ..clear()
      ..addAll(SeedData.users());
    _expenses
      ..clear()
      ..addAll(SeedData.expenses());
    _seq = 100;
    _initialized = true;
  }
}
