import '../models/expense.dart';
import '../models/enums.dart';

/// 承認ルールを1箇所に集約。
/// 将来の多段階承認は、ここに承認ステップの判定を追加するだけで拡張できる。
class ApprovalService {
  ApprovalService._();

  /// 申請する（下書き / 差し戻し -> 申請中）
  static Expense submit(Expense e) => e.copyWith(
        status: ExpenseStatus.submitted,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// 承認（申請中 -> 承認済み）
  static Expense approve(Expense e, String approverId, {String? comment}) =>
      e.copyWith(
        status: ExpenseStatus.approved,
        approvedAt: DateTime.now(),
        approverId: approverId,
        adminComment: comment,
        updatedAt: DateTime.now(),
      );

  /// 差し戻し（申請中 -> 差し戻し）。コメント必須。
  static Expense returnBack(Expense e, String approverId, String comment) {
    assert(comment.trim().isNotEmpty, '差し戻しコメントは必須です');
    return e.copyWith(
      status: ExpenseStatus.returned,
      adminComment: comment.trim(),
      approverId: approverId,
      updatedAt: DateTime.now(),
    );
  }

  /// 精算済みにする（承認済み -> 精算済み）
  static Expense settle(Expense e) => e.copyWith(
        status: ExpenseStatus.settled,
        settledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// 差し戻しコメントのバリデーション
  static String? validateReturnComment(String? v) {
    if (v == null || v.trim().isEmpty) {
      return '差し戻しの理由を入力してください（必須）';
    }
    if (v.trim().length < 5) {
      return '理由は5文字以上で入力してください';
    }
    return null;
  }
}
