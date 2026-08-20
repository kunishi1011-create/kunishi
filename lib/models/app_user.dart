import 'enums.dart';

/// users テーブル相当
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String employeeNo;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.employeeNo,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.code,
        'department': department,
        'employee_no': employeeNo,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        role: UserRole.fromCode((map['role'] as String?) ?? 'employee'),
        department: (map['department'] as String?) ?? '',
        employeeNo: (map['employee_no'] as String?) ?? '',
        createdAt:
            DateTime.tryParse((map['created_at'] as String?) ?? '') ??
                DateTime.now(),
      );
}
