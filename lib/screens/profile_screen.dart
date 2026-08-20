import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/formatters.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.currentUser;
    if (u == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: CenteredContent(
        maxWidth: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          u.name.characters.first,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(u.name,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: u.isAdmin
                            ? AppTheme.statusSubmitted
                                .withValues(alpha: 0.12)
                            : AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              u.isAdmin
                                  ? Icons.admin_panel_settings_outlined
                                  : Icons.person_outline,
                              size: 15,
                              color: u.isAdmin
                                  ? AppTheme.statusSubmitted
                                  : AppTheme.primary),
                          const SizedBox(width: 5),
                          Text(u.role.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: u.isAdmin
                                      ? AppTheme.statusSubmitted
                                      : AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _InfoRow('社員番号', u.employeeNo),
                  _InfoRow('メールアドレス', u.email),
                  _InfoRow('所属部門', u.department),
                  _InfoRow('権限', u.role.label),
                  _InfoRow('登録日', Fmt.date(u.createdAt), isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ログアウト
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ログアウトしますか？',
                        style: TextStyle(fontSize: 18)),
                    content: const Text('再度ログインが必要になります。',
                        style: TextStyle(fontSize: 14.5)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 46)),
                        child: const Text('ログアウト'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(LoginScreen.route, (r) => false);
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('ログアウト'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statusReturned,
                side: const BorderSide(
                    color: AppTheme.statusReturned, width: 1.5),
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KUNISHI経費精算  プロトタイプ v1.0',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSub)),
                  SizedBox(height: 6),
                  Text(
                    'STEP1：画面と画面遷移の確認用（データはブラウザを再読み込みすると初期状態に戻ります）',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSub,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSub)),
              ),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
