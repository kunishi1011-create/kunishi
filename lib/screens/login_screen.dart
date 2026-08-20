import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/seed_data.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      await context.read<ExpenseProvider>().load();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _fillTestUser(String email) {
    _email.text = email;
    _password.text = SeedData.testPassword;
    context.read<AuthProvider>().clearError();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // ロゴ
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'KUNISHI経費精算',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '社内向け経費精算システム（プロトタイプ）',
                    style: TextStyle(fontSize: 13.5, color: AppTheme.textSub),
                  ),
                  const SizedBox(height: 26),

                  // ログインフォーム
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('ログイン',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'メールアドレス',
                                prefixIcon: Icon(Icons.mail_outline),
                                hintText: 'employee@example.com',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'メールアドレスを入力してください';
                                }
                                if (!v.contains('@')) {
                                  return 'メールアドレスの形式が正しくありません';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'パスワード',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  tooltip: _obscure ? 'パスワードを表示' : 'パスワードを隠す',
                                ),
                              ),
                              onFieldSubmitted: (_) => _login(),
                              validator: (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'パスワードを入力してください'
                                      : null,
                            ),

                            // エラー表示
                            if (auth.error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusReturned
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppTheme.statusReturned
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 18,
                                        color: AppTheme.statusReturned),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.error!,
                                        style: const TextStyle(
                                            fontSize: 13.5,
                                            color: AppTheme.statusReturned,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: auth.loading ? null : _login,
                              child: auth.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white),
                                    )
                                  : const Text('ログイン'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // テストユーザー案内（プロトタイプ用）
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science_outlined,
                                  size: 17, color: AppTheme.textSub),
                              const SizedBox(width: 6),
                              const Text('テスト用ユーザー',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSub)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'タップすると自動入力されます（パスワード: password）',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSub),
                          ),
                          const SizedBox(height: 12),
                          _TestUserButton(
                            icon: Icons.person_outline,
                            title: '一般社員',
                            subtitle: 'employee@example.com（山田 太郎 / 営業部）',
                            onTap: () => _fillTestUser('employee@example.com'),
                          ),
                          const SizedBox(height: 8),
                          _TestUserButton(
                            icon: Icons.admin_panel_settings_outlined,
                            title: '管理者',
                            subtitle: 'admin@example.com（田中 誠 / 経理部）',
                            onTap: () => _fillTestUser('admin@example.com'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TestUserButton extends StatelessWidget {
  const _TestUserButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSub)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 17, color: AppTheme.textSub),
          ],
        ),
      ),
    );
  }
}
