import 'package:flutter/foundation.dart';
import '../core/formatters.dart';
import '../data/expense_repository.dart';
import '../models/app_user.dart';
import '../models/expense.dart';
import '../models/enums.dart';
import '../services/approval_service.dart';

/// 月次集計結果
class MonthlySummary {
  final int total; // 申請総額（下書きを除く）
  final int approved; // 承認済み金額（未精算）
  final int pending; // 承認待ち（申請中）金額
  final int returned; // 差し戻し金額
  final int settled; // 精算済み金額
  final int pendingCount; // 承認待ち件数
  final int totalCount;
  final Map<ExpenseCategory, int> byCategory;

  const MonthlySummary({
    required this.total,
    required this.approved,
    required this.pending,
    required this.returned,
    required this.settled,
    required this.pendingCount,
    required this.totalCount,
    required this.byCategory,
  });

  /// 未精算金額 = 承認済みでまだ精算されていない金額
  int get unsettled => approved;

  /// 未承認金額 = 申請中 + 差し戻し
  int get unapproved => pending + returned;

  static const empty = MonthlySummary(
    total: 0,
    approved: 0,
    pending: 0,
    returned: 0,
    settled: 0,
    pendingCount: 0,
    totalCount: 0,
    byCategory: {},
  );
}

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._repo);
  final ExpenseRepository _repo;

  List<Expense> _expenses = [];
  List<AppUser> _users = [];
  bool _loading = true;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  List<AppUser> get users => _users;
  List<AppUser> get employees =>
      _users.where((u) => u.role == UserRole.employee).toList();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.init();
      _users = await _repo.fetchUsers();
      _expenses = await _repo.fetchAllExpenses();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'データの読み込みに失敗しました。再度お試しください。';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refresh() async {
    _expenses = await _repo.fetchAllExpenses();
    notifyListeners();
  }

  // ---------- 参照 ----------

  AppUser? userById(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  String userName(String id) => userById(id)?.name ?? '(不明なユーザー)';

  Expense? byId(String id) {
    for (final e in _expenses) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// 全申請（申請日の新しい順）
  List<Expense> get allExpenses {
    final list = List<Expense>.from(_expenses);
    list.sort(
        (a, b) => b.effectiveSubmittedAt.compareTo(a.effectiveSubmittedAt));
    return list;
  }

  /// 指定ユーザーの申請（申請日の新しい順）
  List<Expense> forUser(String userId) =>
      allExpenses.where((e) => e.userId == userId).toList();

  /// 絞り込み
  /// monthKey: "2025-03" 形式。null は全期間
  List<Expense> filter({
    String? userId,
    String? monthKey,
    ExpenseStatus? status,
    ExpenseCategory? category,
  }) {
    return allExpenses.where((e) {
      if (userId != null && e.userId != userId) return false;
      if (monthKey != null &&
          Fmt.monthKey(e.effectiveSubmittedAt) != monthKey) {
        return false;
      }
      if (status != null && e.status != status) return false;
      if (category != null && e.category != category) return false;
      return true;
    }).toList();
  }

  /// データが存在する月キーの一覧（新しい順）
  List<String> get availableMonthKeys {
    final set = <String>{};
    for (final e in _expenses) {
      set.add(Fmt.monthKey(e.effectiveSubmittedAt));
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  // ---------- 集計 ----------

  /// 月次集計。userId 指定でその社員のみ、null で全社
  MonthlySummary summary({String? userId, String? monthKey}) {
    final target = _expenses.where((e) {
      if (userId != null && e.userId != userId) return false;
      if (monthKey != null &&
          Fmt.monthKey(e.effectiveSubmittedAt) != monthKey) {
        return false;
      }
      return true;
    }).toList();

    int total = 0, approved = 0, pending = 0, returned = 0, settled = 0;
    int pendingCount = 0, totalCount = 0;
    final byCat = <ExpenseCategory, int>{};

    for (final e in target) {
      // 下書きは「申請」に含めない
      if (e.status == ExpenseStatus.draft) continue;

      total += e.amount;
      totalCount++;
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;

      switch (e.status) {
        case ExpenseStatus.submitted:
          pending += e.amount;
          pendingCount++;
          break;
        case ExpenseStatus.approved:
          approved += e.amount;
          break;
        case ExpenseStatus.returned:
          returned += e.amount;
          break;
        case ExpenseStatus.settled:
          settled += e.amount;
          break;
        case ExpenseStatus.draft:
          break;
      }
    }

    final sortedCat = Map.fromEntries(
      byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return MonthlySummary(
      total: total,
      approved: approved,
      pending: pending,
      returned: returned,
      settled: settled,
      pendingCount: pendingCount,
      totalCount: totalCount,
      byCategory: sortedCat,
    );
  }

  /// 当月キー
  String get currentMonthKey => Fmt.monthKey(DateTime.now());

  // ---------- 更新系 ----------

  Future<Expense> create(Expense e) async {
    final created = await _repo.createExpense(e);
    await _refresh();
    return created;
  }

  Future<void> update(Expense e) async {
    await _repo.updateExpense(e);
    await _refresh();
  }

  Future<void> remove(String id) async {
    await _repo.deleteExpense(id);
    await _refresh();
  }

  Future<void> submit(Expense e) async {
    await _repo.updateExpense(ApprovalService.submit(e));
    await _refresh();
  }

  Future<void> approve(Expense e, String approverId) async {
    await _repo.updateExpense(ApprovalService.approve(e, approverId));
    await _refresh();
  }

  Future<void> returnBack(Expense e, String approverId, String comment) async {
    await _repo
        .updateExpense(ApprovalService.returnBack(e, approverId, comment));
    await _refresh();
  }

  Future<void> settle(Expense e) async {
    await _repo.updateExpense(ApprovalService.settle(e));
    await _refresh();
  }
}
