import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_user.dart';
import '../models/expense.dart';
import 'expense_repository.dart';
import 'seed_data.dart';

/// STEP2用：Hive による永続化実装。
///
/// 設計方針
/// - モデルの toMap() / fromMap() をそのまま利用し、Hive の
///   TypeAdapter 自動生成（build_runner）を不要にしている。
///   これによりモデル変更時の再生成漏れによる不整合を避けられる。
/// - 保存形式は Map（JSON互換）なので、STEP2以降で
///   Firestore / Supabase へ移行する際もそのまま流用できる。
/// - キーは id。取得時は必ず createdAt / expenseDate で
///   メモリ上でソートし、DB側のインデックスに依存しない。
class HiveRepository implements ExpenseRepository {
  static const String usersBoxName = 'users';
  static const String expensesBoxName = 'expenses';
  static const String metaBoxName = 'meta';

  /// シードデータの版。値を上げると次回起動時に初期データを再投入する。
  static const int seedVersion = 1;
  static const String _seedVersionKey = 'seed_version';
  static const String _seqKey = 'expense_seq';

  Box<Map<dynamic, dynamic>>? _users;
  Box<Map<dynamic, dynamic>>? _expenses;
  Box<dynamic>? _meta;

  bool _initialized = false;
  Future<void>? _initFuture;

  // ---------------------------------------------------------------- init

  @override
  Future<void> init() => _ensureInit();

  /// 初期化ガード。
  /// どのメソッドから最初に呼ばれても安全で、同時呼び出しでも
  /// 1回しか実行されない（_initFuture を共有する）。
  Future<void> _ensureInit() {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    await Hive.initFlutter();

    _users = await Hive.openBox<Map<dynamic, dynamic>>(usersBoxName);
    _expenses = await Hive.openBox<Map<dynamic, dynamic>>(expensesBoxName);
    _meta = await Hive.openBox<dynamic>(metaBoxName);

    final stored = (_meta!.get(_seedVersionKey) as num?)?.toInt() ?? 0;
    if (stored < seedVersion || _users!.isEmpty) {
      await _seed();
    }

    _initialized = true;
  }

  /// 初期データ投入。
  /// users は毎回入れ替える（マスタ相当）が、
  /// expenses は既存データを尊重し、空のときだけ投入する。
  Future<void> _seed() async {
    await _users!.clear();
    for (final u in SeedData.users()) {
      await _users!.put(u.id, u.toMap());
    }

    if (_expenses!.isEmpty) {
      for (final e in SeedData.expenses()) {
        await _expenses!.put(e.id, e.toMap());
      }
      await _meta!.put(_seqKey, 100);
    }

    await _meta!.put(_seedVersionKey, seedVersion);
  }

  /// 検証用：保存データを破棄して初期状態に戻す。
  @override
  Future<void> resetToSeed() async {
    await _ensureInit();
    await _users!.clear();
    await _expenses!.clear();
    await _meta!.clear();
    await _seed();
  }

  // ------------------------------------------------------------- helpers

  /// Hive から読み出した動的キーの Map を、キーを String に揃えて変換する。
  static Map<String, dynamic> _normalize(Map<dynamic, dynamic> raw) {
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }

  Future<int> _nextSeq() async {
    final current = (_meta!.get(_seqKey) as num?)?.toInt() ?? 100;
    final next = current + 1;
    await _meta!.put(_seqKey, next);
    return next;
  }

  // ---------------------------------------------------------------- users

  @override
  Future<List<AppUser>> fetchUsers() async {
    await _ensureInit();
    final list = _users!.values.map((m) => AppUser.fromMap(_normalize(m))).toList()
      // 管理者を先頭、その後は社員番号順（表示の安定化）
      ..sort((a, b) {
        if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
        return a.employeeNo.compareTo(b.employeeNo);
      });
    return List.unmodifiable(list);
  }

  @override
  Future<AppUser?> findUserByEmail(String email) async {
    await _ensureInit();
    final target = email.trim().toLowerCase();
    for (final m in _users!.values) {
      final u = AppUser.fromMap(_normalize(m));
      if (u.email.toLowerCase() == target) return u;
    }
    return null;
  }

  @override
  Future<AppUser?> signIn(String email, String password) async {
    await _ensureInit();
    // プロトタイプ用の簡易認証。
    // 本番では Firebase Auth / Supabase Auth に差し替える。
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final user = await findUserByEmail(email);
    if (user == null) return null;
    if (password.trim() != SeedData.testPassword) return null;
    return user;
  }

  // ------------------------------------------------------------- expenses

  List<Expense> _allSorted() {
    final list = _expenses!.values
        .map((m) => Expense.fromMap(_normalize(m)))
        .toList()
      // 利用日の新しい順。DB側のソート／複合インデックスに依存しない。
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return list;
  }

  @override
  Future<List<Expense>> fetchAllExpenses() async {
    await _ensureInit();
    return List.unmodifiable(_allSorted());
  }

  @override
  Future<List<Expense>> fetchExpensesByUser(String userId) async {
    await _ensureInit();
    return _allSorted().where((e) => e.userId == userId).toList();
  }

  @override
  Future<Expense?> findExpense(String id) async {
    await _ensureInit();
    final raw = _expenses!.get(id);
    if (raw == null) return null;
    return Expense.fromMap(_normalize(raw));
  }

  @override
  Future<Expense> createExpense(Expense expense) async {
    await _ensureInit();
    var target = expense;
    if (target.id.isEmpty) {
      final seq = await _nextSeq();
      target = Expense.fromMap({
        ...expense.toMap(),
        'id': 'ex_${seq.toString().padLeft(3, '0')}',
      });
    }
    await _expenses!.put(target.id, target.toMap());
    return target;
  }

  @override
  Future<Expense> updateExpense(Expense expense) async {
    await _ensureInit();
    await _expenses!.put(expense.id, expense.toMap());
    return expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _ensureInit();
    await _expenses!.delete(id);
  }
}
