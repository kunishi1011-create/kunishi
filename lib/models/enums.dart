import 'package:flutter/material.dart';

/// ユーザー権限
enum UserRole {
  employee('employee', '一般社員'),
  admin('admin', '管理者');

  const UserRole(this.code, this.label);
  final String code;
  final String label;

  static UserRole fromCode(String code) =>
      UserRole.values.firstWhere((e) => e.code == code,
          orElse: () => UserRole.employee);
}

/// 申請ステータス
/// 色だけに依存しないよう label を必ず併記して表示する
enum ExpenseStatus {
  draft('draft', '下書き', Icons.edit_note),
  submitted('submitted', '申請中', Icons.schedule),
  approved('approved', '承認済み', Icons.check_circle_outline),
  returned('returned', '差し戻し', Icons.undo),
  settled('settled', '精算済み', Icons.paid);

  const ExpenseStatus(this.code, this.label, this.icon);
  final String code;
  final String label;
  final IconData icon;

  static ExpenseStatus fromCode(String code) =>
      ExpenseStatus.values.firstWhere((e) => e.code == code,
          orElse: () => ExpenseStatus.draft);

  /// 社員が編集・削除できるか（未承認のみ）
  bool get isEditableByEmployee =>
      this == ExpenseStatus.draft || this == ExpenseStatus.returned;

  /// 管理者が承認・差し戻しできるか
  bool get isReviewable => this == ExpenseStatus.submitted;

  /// 精算済みにできるか
  bool get isSettleable => this == ExpenseStatus.approved;
}

/// 経費区分
enum ExpenseCategory {
  transport('transport', '交通費', Icons.train),
  lodging('lodging', '宿泊費', Icons.hotel),
  meeting('meeting', '会議費', Icons.groups),
  entertainment('entertainment', '接待交際費', Icons.restaurant),
  supplies('supplies', '消耗品費', Icons.inventory_2),
  communication('communication', '通信費', Icons.wifi),
  vehicle('vehicle', '車両費', Icons.directions_car),
  welfare('welfare', '福利厚生費', Icons.favorite_border),
  other('other', 'その他', Icons.more_horiz);

  const ExpenseCategory(this.code, this.label, this.icon);
  final String code;
  final String label;
  final IconData icon;

  static ExpenseCategory fromCode(String code) =>
      ExpenseCategory.values.firstWhere((e) => e.code == code,
          orElse: () => ExpenseCategory.other);
}

/// 支払方法
enum PaymentMethod {
  cash('cash', '現金'),
  personalCard('personal_card', '個人クレジットカード'),
  corporateCard('corporate_card', '法人クレジットカード'),
  other('other', 'その他');

  const PaymentMethod(this.code, this.label);
  final String code;
  final String label;

  static PaymentMethod fromCode(String code) =>
      PaymentMethod.values.firstWhere((e) => e.code == code,
          orElse: () => PaymentMethod.other);
}
