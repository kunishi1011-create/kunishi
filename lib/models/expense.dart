import 'enums.dart';

/// expenses テーブル相当
///
/// 将来拡張用フィールド（taxRate / invoiceNumber / approverId）は
/// プロトタイプでは未使用だが、DB設計上あらかじめ保持しておく。
class Expense {
  final String id;
  final String userId;

  // 必須項目
  final DateTime expenseDate;
  final ExpenseCategory category;
  final int amount; // 税込金額（円・整数）
  final String vendor;
  final String description;
  final PaymentMethod paymentMethod;

  // 任意項目
  final String? department;
  final String? projectName;
  final String? notes;
  final String? receiptUrl;

  // ステータス管理
  final ExpenseStatus status;
  final String? adminComment;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? settledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 将来拡張用
  final String? approverId;
  final int? taxRate;
  final String? invoiceNumber;

  const Expense({
    required this.id,
    required this.userId,
    required this.expenseDate,
    required this.category,
    required this.amount,
    required this.vendor,
    required this.description,
    required this.paymentMethod,
    this.department,
    this.projectName,
    this.notes,
    this.receiptUrl,
    required this.status,
    this.adminComment,
    this.submittedAt,
    this.approvedAt,
    this.settledAt,
    required this.createdAt,
    required this.updatedAt,
    this.approverId,
    this.taxRate,
    this.invoiceNumber,
  });

  /// 集計上の「申請日」。申請前（下書き）は作成日を使う
  DateTime get effectiveSubmittedAt => submittedAt ?? createdAt;

  /// 未精算（承認済みだがまだ精算されていない）
  bool get isUnsettled => status == ExpenseStatus.approved;

  Expense copyWith({
    DateTime? expenseDate,
    ExpenseCategory? category,
    int? amount,
    String? vendor,
    String? description,
    PaymentMethod? paymentMethod,
    String? department,
    String? projectName,
    String? notes,
    String? receiptUrl,
    ExpenseStatus? status,
    String? adminComment,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? settledAt,
    DateTime? updatedAt,
    String? approverId,
    int? taxRate,
    String? invoiceNumber,
  }) {
    return Expense(
      id: id,
      userId: userId,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      vendor: vendor ?? this.vendor,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      department: department ?? this.department,
      projectName: projectName ?? this.projectName,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      status: status ?? this.status,
      adminComment: adminComment ?? this.adminComment,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      approverId: approverId ?? this.approverId,
      taxRate: taxRate ?? this.taxRate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'expense_date': expenseDate.toIso8601String(),
        'category': category.code,
        'amount': amount,
        'vendor': vendor,
        'description': description,
        'payment_method': paymentMethod.code,
        'department': department,
        'project_name': projectName,
        'notes': notes,
        'receipt_url': receiptUrl,
        'status': status.code,
        'admin_comment': adminComment,
        'submitted_at': submittedAt?.toIso8601String(),
        'approved_at': approvedAt?.toIso8601String(),
        'settled_at': settledAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'approver_id': approverId,
        'tax_rate': taxRate,
        'invoice_number': invoiceNumber,
      };

  factory Expense.fromMap(Map<String, dynamic> map) {
    DateTime? parse(Object? v) =>
        v is String ? DateTime.tryParse(v) : null;
    return Expense(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      expenseDate: parse(map['expense_date']) ?? DateTime.now(),
      category:
          ExpenseCategory.fromCode((map['category'] as String?) ?? 'other'),
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      vendor: (map['vendor'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      paymentMethod:
          PaymentMethod.fromCode((map['payment_method'] as String?) ?? 'cash'),
      department: map['department'] as String?,
      projectName: map['project_name'] as String?,
      notes: map['notes'] as String?,
      receiptUrl: map['receipt_url'] as String?,
      status: ExpenseStatus.fromCode((map['status'] as String?) ?? 'draft'),
      adminComment: map['admin_comment'] as String?,
      submittedAt: parse(map['submitted_at']),
      approvedAt: parse(map['approved_at']),
      settledAt: parse(map['settled_at']),
      createdAt: parse(map['created_at']) ?? DateTime.now(),
      updatedAt: parse(map['updated_at']) ?? DateTime.now(),
      approverId: map['approver_id'] as String?,
      taxRate: (map['tax_rate'] as num?)?.toInt(),
      invoiceNumber: map['invoice_number'] as String?,
    );
  }
}
