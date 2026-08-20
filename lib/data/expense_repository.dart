import '../models/app_user.dart';
import '../models/expense.dart';

/// データアクセスの抽象インターフェース。
///
/// ★差し替え点：
///   STEP1 -> MockRepository（メモリ上のダミーデータ）
///   STEP2 -> HiveRepository / FirestoreRepository / SupabaseRepository
/// 画面側はこのインターフェースにのみ依存するため、
/// 実装を差し替えても UI コードは変更不要。
abstract class ExpenseRepository {
  /// 初期化（DB接続・シード投入など）
  Future<void> init();

  // ---- users ----
  Future<List<AppUser>> fetchUsers();
  Future<AppUser?> findUserByEmail(String email);

  /// 認証。成功でユーザー、失敗で null
  Future<AppUser?> signIn(String email, String password);

  // ---- expenses ----
  Future<List<Expense>> fetchAllExpenses();
  Future<List<Expense>> fetchExpensesByUser(String userId);
  Future<Expense?> findExpense(String id);

  Future<Expense> createExpense(Expense expense);
  Future<Expense> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);

  /// 検証用：保存データを破棄して初期テストデータに戻す。
  /// プロトタイプで動作確認を繰り返すために用意している。
  Future<void> resetToSeed();
}
