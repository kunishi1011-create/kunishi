import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';

/// 経費申請フォーム（新規 / 編集 兼用）
/// スマホでの入力しやすさを優先：1列レイアウト、大きめの入力欄、
/// 必須/任意をセクションで分離して詰め込みすぎない構成。
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.editing});
  final Expense? editing;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _expenseDate;
  ExpenseCategory? _category;
  PaymentMethod? _paymentMethod;
  final _amount = TextEditingController();
  final _vendor = TextEditingController();
  final _description = TextEditingController();
  final _department = TextEditingController();
  final _projectName = TextEditingController();
  final _notes = TextEditingController();
  String? _receiptUrl;
  bool _saving = false;

  bool get isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _expenseDate = e.expenseDate;
      _category = e.category;
      _paymentMethod = e.paymentMethod;
      _amount.text = e.amount.toString();
      _vendor.text = e.vendor;
      _description.text = e.description;
      _department.text = e.department ?? '';
      _projectName.text = e.projectName ?? '';
      _notes.text = e.notes ?? '';
      _receiptUrl = e.receiptUrl;
    } else {
      _expenseDate = DateTime.now();
      // 所属部門を初期値として自動入力
      final u = context.read<AuthProvider>().currentUser;
      _department.text = u?.department ?? '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _vendor.dispose();
    _description.dispose();
    _department.dispose();
    _projectName.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: '利用日を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
      locale: const Locale('ja'),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  /// status: draft = 下書き保存 / submitted = 申請
  Future<void> _save(ExpenseStatus status) async {
    if (status == ExpenseStatus.submitted &&
        !_formKey.currentState!.validate()) {
      // 未入力箇所へ気付けるようメッセージを出す
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未入力の必須項目があります。ご確認ください。')),
      );
      return;
    }
    // 下書きでも金額と区分は最低限必要
    if (status == ExpenseStatus.draft) {
      if (_category == null || _amount.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下書き保存には「経費区分」と「金額」が必要です。')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    final ep = context.read<ExpenseProvider>();
    final user = context.read<AuthProvider>().currentUser!;
    final now = DateTime.now();
    final amount = int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;

    String? nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

    try {
      if (isEdit) {
        final e = widget.editing!;
        final updated = e.copyWith(
          expenseDate: _expenseDate,
          category: _category,
          amount: amount,
          vendor: _vendor.text.trim(),
          description: _description.text.trim(),
          paymentMethod: _paymentMethod,
          department: nullIfEmpty(_department.text),
          projectName: nullIfEmpty(_projectName.text),
          notes: nullIfEmpty(_notes.text),
          receiptUrl: _receiptUrl,
          status: status,
          submittedAt:
              status == ExpenseStatus.submitted ? now : e.submittedAt,
          updatedAt: now,
        );
        await ep.update(updated);
      } else {
        final created = Expense(
          id: '',
          userId: user.id,
          expenseDate: _expenseDate,
          category: _category!,
          amount: amount,
          vendor: _vendor.text.trim(),
          description: _description.text.trim(),
          paymentMethod: _paymentMethod ?? PaymentMethod.cash,
          department: nullIfEmpty(_department.text),
          projectName: nullIfEmpty(_projectName.text),
          notes: nullIfEmpty(_notes.text),
          receiptUrl: _receiptUrl,
          status: status,
          submittedAt: status == ExpenseStatus.submitted ? now : null,
          createdAt: now,
          updatedAt: now,
          taxRate: 10,
        );
        await ep.create(created);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == ExpenseStatus.submitted
              ? '申請しました。管理者の承認をお待ちください。'
              : '下書きとして保存しました。'),
          backgroundColor: AppTheme.statusApproved,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('保存に失敗しました。もう一度お試しください。'),
            backgroundColor: AppTheme.statusReturned),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '経費申請を編集' : '新規経費申請'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: Responsive.pagePadding(context)
                .copyWith(bottom: 120),
            children: [
              CenteredContent(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== 必須項目 =====
                    const _SectionHeader(
                        title: '必須項目', icon: Icons.edit_outlined),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 利用日
                            _FieldLabel('利用日', required: true),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 17),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 19,
                                        color: AppTheme.primary),
                                    const SizedBox(width: 11),
                                    Text(
                                      Fmt.date(_expenseDate),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    const Text('変更',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.primary,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 経費区分（プルダウン）
                            _FieldLabel('経費区分', required: true),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<ExpenseCategory>(
                              initialValue: _category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: '選択してください',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: ExpenseCategory.values
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Row(
                                          children: [
                                            Icon(c.icon,
                                                size: 18,
                                                color: AppTheme.primary),
                                            const SizedBox(width: 9),
                                            Text(c.label),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _category = v),
                              validator: (v) =>
                                  v == null ? '経費区分を選択してください' : null,
                            ),
                            const SizedBox(height: 18),

                            // 金額
                            _FieldLabel('金額（税込）', required: true),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _amount,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(9),
                              ],
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixText: '¥ ',
                                prefixStyle: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSub),
                                suffixText: amountValue > 0
                                    ? '（${Fmt.yen(amountValue)}）'
                                    : null,
                                helperText: '消費税を含んだ金額を入力してください',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                final n = int.tryParse(
                                    (v ?? '').replaceAll(',', ''));
                                if (n == null || n <= 0) {
                                  return '金額を入力してください';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // 支払先
                            _FieldLabel('支払先', required: true),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _vendor,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: '例：JR東日本 / 株式会社◯◯',
                                prefixIcon: Icon(Icons.store_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? '支払先を入力してください'
                                      : null,
                            ),
                            const SizedBox(height: 18),

                            // 内容
                            _FieldLabel('内容', required: true),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _description,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: '例：A社訪問 交通費（東京→横浜 往復）',
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? '内容を入力してください'
                                      : null,
                            ),
                            const SizedBox(height: 18),

                            // 支払方法
                            _FieldLabel('支払方法', required: true),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<PaymentMethod>(
                              initialValue: _paymentMethod,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: '選択してください',
                                prefixIcon: Icon(Icons.payment_outlined),
                              ),
                              items: PaymentMethod.values
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p.label)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v),
                              validator: (v) =>
                                  v == null ? '支払方法を選択してください' : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== 任意項目 =====
                    const _SectionHeader(
                        title: '任意項目', icon: Icons.more_horiz),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel('部門'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _department,
                              decoration: const InputDecoration(
                                hintText: '例：営業部',
                                prefixIcon:
                                    Icon(Icons.apartment_outlined),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _FieldLabel('プロジェクト名'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _projectName,
                              decoration: const InputDecoration(
                                hintText: '例：新規開拓A',
                                prefixIcon: Icon(Icons.folder_outlined),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _FieldLabel('備考'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _notes,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: '参加者名や補足事項など',
                              ),
                            ),
                            const SizedBox(height: 18),
                            _FieldLabel('領収書画像'),
                            const SizedBox(height: 6),
                            _ReceiptPicker(
                              receiptUrl: _receiptUrl,
                              onPicked: (v) =>
                                  setState(() => _receiptUrl = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 操作ボタンは常に画面下部に固定（スマホで押しやすい）
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: CenteredContent(
              maxWidth: 720,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => _save(ExpenseStatus.draft),
                      child: const Text('下書き保存'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _save(ExpenseStatus.submitted),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white))
                          : const Icon(Icons.send, size: 19),
                      label: Text(isEdit ? '再申請する' : '申請する'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSub),
        const SizedBox(width: 7),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSub)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain)),
        if (required) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.statusReturned.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('必須',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusReturned)),
          ),
        ],
      ],
    );
  }
}

/// 領収書画像の擬似アップローダー。
/// 将来：スマホカメラ撮影 → Storage アップロード → OCR に置き換える想定。
class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({required this.receiptUrl, required this.onPicked});
  final String? receiptUrl;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context) {
    if (receiptUrl != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long, size: 22, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receiptUrl!,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const Text('添付済み',
                      style: TextStyle(
                          fontSize: 11.5, color: AppTheme.textSub)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onPicked(null),
              icon: const Icon(Icons.close, size: 20),
              tooltip: '添付を削除',
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPicked(
                    'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg'),
                icon: const Icon(Icons.photo_camera_outlined, size: 19),
                label: const Text('撮影'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    textStyle: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPicked(
                    'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg'),
                icon: const Icon(Icons.attach_file, size: 19),
                label: const Text('ファイル選択'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    textStyle: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '※ プロトタイプでは実際の画像は保存されません（将来スマホ撮影＋OCRに対応予定）',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textSub),
        ),
      ],
    );
  }
}
