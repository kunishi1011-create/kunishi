import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_list_screen.dart';
import 'admin/monthly_report_screen.dart';
import 'employee/employee_dashboard.dart';
import 'employee/expense_form_screen.dart';
import 'employee/expense_list_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// ログイン後の枠。
/// モバイル : 下部ナビゲーション
/// PC/タブレット : 左サイドナビゲーション
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  static const route = '/';

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  bool _adminListPendingOnly = true;

  void _go(int i, {bool pendingOnly = true}) {
    setState(() {
      _index = i;
      _adminListPendingOnly = pendingOnly;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ep = context.watch<ExpenseProvider>();
    final user = auth.currentUser;

    // 未ログインならログイン画面へ
    if (user == null) {
      return const LoginScreen();
    }

    if (ep.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (ep.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 46, color: AppTheme.statusReturned),
                const SizedBox(height: 12),
                Text(ep.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => context.read<ExpenseProvider>().load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('再読み込み'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAdmin = user.isAdmin;
    final pendingCount = ep.allExpenses
        .where((e) => e.status == ExpenseStatus.submitted)
        .length;

    // 権限ごとのタブ定義
    final tabs = isAdmin
        ? <_TabDef>[
            const _TabDef('ホーム', Icons.home_outlined, Icons.home),
            _TabDef('申請一覧', Icons.list_alt, Icons.list_alt,
                badge: pendingCount),
            const _TabDef('月次集計', Icons.bar_chart_outlined, Icons.bar_chart),
            const _TabDef('設定', Icons.person_outline, Icons.person),
          ]
        : <_TabDef>[
            const _TabDef('ホーム', Icons.home_outlined, Icons.home),
            const _TabDef('申請一覧', Icons.list_alt, Icons.list_alt),
            const _TabDef('新規申請', Icons.add_circle_outline,
                Icons.add_circle),
            const _TabDef('設定', Icons.person_outline, Icons.person),
          ];

    final safeIndex = _index.clamp(0, tabs.length - 1);

    Widget body;
    if (isAdmin) {
      switch (safeIndex) {
        case 0:
          body = AdminDashboard(
            onNavigateToList: () => _go(1, pendingOnly: true),
            onNavigateToReport: () => _go(2),
          );
          break;
        case 1:
          body = AdminListScreen(
            key: ValueKey('admin_list_$_adminListPendingOnly'),
            initialPendingOnly: _adminListPendingOnly,
          );
          break;
        case 2:
          body = const MonthlyReportScreen();
          break;
        default:
          body = const ProfileScreen();
      }
    } else {
      switch (safeIndex) {
        case 0:
          body = EmployeeDashboard(onNavigateToList: () => _go(1));
          break;
        case 1:
          body = const ExpenseListScreen();
          break;
        case 2:
          // 新規申請はモーダルで開き、ホームに戻す
          body = EmployeeDashboard(onNavigateToList: () => _go(1));
          break;
        default:
          body = const ProfileScreen();
      }
    }

    final title = isAdmin
        ? ['KUNISHI経費精算', '申請一覧（全社）', '月次集計', '設定'][safeIndex]
        : ['KUNISHI経費精算', '自分の申請一覧', '新規申請', '設定'][safeIndex];

    final isWide = !Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // 権限バッジ（誤操作防止のため常に表示）
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                    isAdmin
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline,
                    size: 15,
                    color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  '${user.role.label}　${user.name}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  // PC/タブレット：サイドナビ
                  Container(
                    width: 208,
                    color: Colors.white,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        for (var i = 0; i < tabs.length; i++)
                          _SideNavItem(
                            tab: tabs[i],
                            selected: safeIndex == i,
                            onTap: () => _onTabTap(i, isAdmin),
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => _onTabTap(i, isAdmin),
              destinations: tabs
                  .map((t) => NavigationDestination(
                        icon: t.badge != null && t.badge! > 0
                            ? Badge(
                                label: Text('${t.badge}'),
                                child: Icon(t.icon),
                              )
                            : Icon(t.icon),
                        selectedIcon: Icon(t.selectedIcon),
                        label: t.label,
                      ))
                  .toList(),
            ),
    );
  }

  void _onTabTap(int i, bool isAdmin) {
    // 一般社員の「新規申請」タブはフォームをモーダルで開く
    if (!isAdmin && i == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
      );
      return;
    }
    _go(i, pendingOnly: i == 1 ? true : _adminListPendingOnly);
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon, this.selectedIcon, {this.badge});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? badge;
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _TabDef tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryLight : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(selected ? tab.selectedIcon : tab.icon,
                  size: 21,
                  color:
                      selected ? AppTheme.primary : AppTheme.textSub),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color:
                        selected ? AppTheme.primary : AppTheme.textSub,
                  ),
                ),
              ),
              if (tab.badge != null && tab.badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSubmitted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${tab.badge}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
