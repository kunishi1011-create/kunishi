import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/formatters.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../services/approval_service.dart';
import '../widgets/status_chip.dart';
import 'employee/expense_form_screen.dart';

/// 申請詳細。
/// 社員 : 未承認（下書き・差し戻し）なら 編集 / 削除 / 申請
/// 管理者: 申請中なら 承認 / 差し戻し、承認済みなら 精算済みにする
class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});
  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final e = ep.byId(expenseId);
    final me = auth.currentUser;

    if (e == null || me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('申請詳細')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Text('この申請は削除されました。',
                style: TextStyle(fontSize: 15, color: AppTheme.textSub)),
          ),
        ),
      );
    }

    final applicant = ep.userById(e.userId);
    final isOwner = e.userId == me.id;
    final isAdmin = me.isAdmin;

    // 権限判定
    final canEdit = isOwner && e.status.isEditableByEmployee;
    final canReview = isAdmin && e.status.isReviewable;
    final canSettle = isAdmin && e.status.isSettleable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('申請詳細'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, e),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: Responsive.pagePadding(context).copyWith(bottom: 40),
          children: [
            CenteredContent(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== 金額とステータス =====
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(e.category.icon,
                                    size: 21, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(e.category.label,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textSub)),
                                    const SizedBox(height: 2),
                                    Text(e.vendor,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              StatusChip(e.status),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          const Text('金額（税込）',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textSub)),
                          const SizedBox(height: 3),
                          Text(
                            Fmt.yen(e.amount),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ===== 差し戻しコメント（最優先で目に入る位置） =====
                  if (e.status == ExpenseStatus.returned &&
                      (e.adminComment ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _CommentBox(
                      title: '差し戻し理由（管理者コメント）',
                      body: e.adminComment!,
                      color: AppTheme.statusReturned,
                      icon: Icons.undo,
                    ),
                  ],

                  // ===== 精算完了の案内 =====
                  if (e.status == ExpenseStatus.settled) ...[
                    const SizedBox(height: 14),
                    _CommentBox(
                      title: '精算済み',
                      body: '精算日：${Fmt.date(e.settledAt)}\nお支払いが完了しています。',
                      color: AppTheme.statusSettled,
                      icon: Icons.paid,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ===== 申請内容 =====
                  const _SectionHeader('申請内容'),
                  const SizedBox(height: 9),
                  Card(
                    child: Column(
                      children: [
                        _Row('申請者',
                            '${applicant?.name ?? '—'}（${applicant?.department ?? '—'}）'),
                        _Row('利用日', Fmt.date(e.expenseDate)),
                        _Row('経費区分', e.category.label),
                        _Row('金額', Fmt.yen(e.amount)),
                        _Row('支払先', e.vendor),
                        _Row('支払方法', e.paymentMethod.label),
                        _Row('内容', e.description, multiline: true),
                        _Row('部門', e.department ?? '—'),
                        _Row('プロジェクト名', e.projectName ?? '—'),
                        _Row('備考', e.notes ?? '—',
                            multiline: true, isLast: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===== 領収書 =====
                  const _SectionHeader('領収書画像'),
                  const SizedBox(height: 9),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: e.receiptUrl == null
                          ? Row(
                              children: const [
                                Icon(Icons.image_not_supported_outlined,
                                    size: 20, color: AppTheme.textSub),
                                SizedBox(width: 9),
                                Text('添付なし',
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        color: AppTheme.textSub)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // プロトタイプではプレースホルダー表示
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius:
                                        BorderRadius.circular(9),
                                    border: Border.all(
                                        color: AppTheme.border),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long,
                                            size: 38,
                                            color: AppTheme.textSub),
                                        SizedBox(height: 7),
                                        Text('領収書画像（プロトタイプのため未表示）',
                                            style: TextStyle(
                                                fontSize: 12.5,
                                                color:
                                                    AppTheme.textSub)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(e.receiptUrl!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSub)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===== 履歴 =====
                  const _SectionHeader('処理履歴'),
                  const SizedBox(height: 9),
                  Card(
                    child: Column(
                      children: [
                        _Row('現在のステータス', e.status.label),
                        _Row('管理者コメント', e.adminComment ?? '—',
                            multiline: true),
                        _Row('申請日時', Fmt.dateTime(e.submittedAt)),
                        _Row('承認日時', Fmt.dateTime(e.approvedAt)),
                        _Row('精算日', Fmt.date(e.settledAt)),
                        _Row('作成日時', Fmt.dateTime(e.createdAt)),
                        _Row('更新日時', Fmt.dateTime(e.updatedAt),
                            isLast: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ===== 操作ボタン =====
                  if (canReview) ...[
                    const _SectionHeader('承認処理'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showReturnDialog(context, e, me.id),
                            icon: const Icon(Icons.undo, size: 20),
                            label: const Text('差し戻し'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.statusReturned,
                              side: const BorderSide(
                                  color: AppTheme.statusReturned,
                                  width: 1.5),
                              minimumSize: const Size(0, 56),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _confirmApprove(context, e, me.id),
                            icon: const Icon(Icons.check, size: 21),
                            label: const Text('承認する'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusApproved,
                              minimumSize: const Size(0, 56),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (canSettle) ...[
                    const _SectionHeader('精算処理'),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmSettle(context, e),
                        icon: const Icon(Icons.paid, size: 21),
                        label: const Text('精算済みにする'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusSettled,
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                  ],

                  if (canEdit) ...[
                    const _SectionHeader('この申請を編集'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final changed =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExpenseFormScreen(editing: e),
                                ),
                              );
                              if (changed == true && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            label: const Text('内容を修正'),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 56)),
                          ),
                        ),
                        if (e.status == ExpenseStatus.draft ||
                            e.status == ExpenseStatus.returned) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmSubmit(context, e),
                              icon: const Icon(Icons.send, size: 20),
                              label: Text(
                                  e.status == ExpenseStatus.returned
                                      ? '再申請'
                                      : '申請する'),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 56)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // 操作できない場合の説明（迷わせない）
                  if (!canEdit && !canReview && !canSettle) ...[
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: AppTheme.textSub),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              _noActionReason(e, isOwner, isAdmin),
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppTheme.textSub,
                                  height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _noActionReason(Expense e, bool isOwner, bool isAdmin) {
    if (isOwner) {
      switch (e.status) {
        case ExpenseStatus.submitted:
          return '現在「申請中」です。管理者の承認をお待ちください。承認前に修正が必要な場合は管理者にご連絡ください。';
        case ExpenseStatus.approved:
          return '承認済みです。経理部での精算処理をお待ちください。';
        case ExpenseStatus.settled:
          return '精算が完了しています。';
        default:
          return 'この申請に対して行える操作はありません。';
      }
    }
    if (isAdmin) {
      switch (e.status) {
        case ExpenseStatus.settled:
          return '精算済みのため、これ以上の操作はありません。';
        case ExpenseStatus.returned:
          return '差し戻し済みです。申請者による再申請をお待ちください。';
        default:
          return 'この申請に対して行える操作はありません。';
      }
    }
    return 'この申請を操作する権限がありません。';
  }

  // ---------- 各種操作 ----------

  Future<void> _confirmApprove(
      BuildContext context, Expense e, String adminId) async {
    final ok = await _confirmDialog(
      context,
      title: 'この申請を承認しますか？',
      message:
          '${Fmt.yen(e.amount)}（${e.category.label} / ${e.vendor}）を承認します。\n承認後は精算処理へ進みます。',
      confirmLabel: '承認する',
      confirmColor: AppTheme.statusApproved,
      icon: Icons.check_circle_outline,
    );
    if (ok != true || !context.mounted) return;
    await context.read<ExpenseProvider>().approve(e, adminId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('承認しました。'),
          backgroundColor: AppTheme.statusApproved),
    );
  }

  Future<void> _confirmSettle(BuildContext context, Expense e) async {
    final ok = await _confirmDialog(
      context,
      title: '精算済みにしますか？',
      message:
          '${Fmt.yen(e.amount)} を精算済みとして記録します。\n精算日には本日の日付が設定されます。',
      confirmLabel: '精算済みにする',
      confirmColor: AppTheme.statusSettled,
      icon: Icons.paid,
    );
    if (ok != true || !context.mounted) return;
    await context.read<ExpenseProvider>().settle(e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('精算済みにしました。'),
          backgroundColor: AppTheme.statusSettled),
    );
  }

  Future<void> _confirmSubmit(BuildContext context, Expense e) async {
    final ok = await _confirmDialog(
      context,
      title: 'この内容で申請しますか？',
      message: '${Fmt.yen(e.amount)}（${e.category.label}）を申請します。',
      confirmLabel: '申請する',
      confirmColor: AppTheme.primary,
      icon: Icons.send,
    );
    if (ok != true || !context.mounted) return;
    await context.read<ExpenseProvider>().submit(e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('申請しました。管理者の承認をお待ちください。'),
          backgroundColor: AppTheme.statusApproved),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Expense e) async {
    final ok = await _confirmDialog(
      context,
      title: 'この申請を削除しますか？',
      message: '${e.category.label} / ${Fmt.yen(e.amount)}\nこの操作は取り消せません。',
      confirmLabel: '削除する',
      confirmColor: AppTheme.statusReturned,
      icon: Icons.delete_outline,
    );
    if (ok != true || !context.mounted) return;
    await context.read<ExpenseProvider>().remove(e.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('申請を削除しました。')),
    );
  }

  /// 差し戻しダイアログ（コメント必須）
  Future<void> _showReturnDialog(
      BuildContext context, Expense e, String adminId) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.undo, color: AppTheme.statusReturned, size: 22),
            SizedBox(width: 9),
            Text('申請を差し戻す', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '申請者に修正内容が伝わるよう、差し戻しの理由を必ず入力してください。',
                  style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textSub,
                      height: 1.45),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '差し戻し理由（必須）',
                    hintText: '例：領収書の添付がありません。画像を添付のうえ再申請してください。',
                    alignLabelWithHint: true,
                  ),
                  validator: ApprovalService.validateReturnComment,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusReturned,
                minimumSize: const Size(0, 46)),
            child: const Text('差し戻す'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) {
      controller.dispose();
      return;
    }
    final comment = controller.text;
    controller.dispose();
    await context.read<ExpenseProvider>().returnBack(e, adminId, comment);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('差し戻しました。申請者に修正を依頼しました。'),
          backgroundColor: AppTheme.statusReturned),
    );
  }

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: confirmColor, size: 22),
            const SizedBox(width: 9),
            Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(message,
            style: const TextStyle(fontSize: 14.5, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                minimumSize: const Size(0, 46)),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSub));
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value,
      {this.multiline = false, this.isLast = false});
  final String label;
  final String value;
  final bool multiline;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: multiline
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSub)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 118,
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSub)),
                    ),
                    Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4)),
                    ),
                  ],
                ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _CommentBox extends StatelessWidget {
  const _CommentBox({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 14.5, color: AppTheme.textMain, height: 1.55)),
        ],
      ),
    );
  }
}
