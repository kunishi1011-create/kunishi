import 'package:intl/intl.dart';

/// 金額・日付の表示形式を一元管理
class Fmt {
  Fmt._();

  static final _yen = NumberFormat('#,##0', 'ja_JP');
  static final _date = DateFormat('yyyy/MM/dd');
  static final _dateShort = DateFormat('MM/dd');
  static final _dateTime = DateFormat('yyyy/MM/dd HH:mm');
  static final _month = DateFormat('yyyy年M月');

  /// 1200000 -> "1,200,000円"
  static String yen(int v) => '${_yen.format(v)}円';

  /// 1200000 -> "¥1,200,000"
  static String yenSymbol(int v) => '¥${_yen.format(v)}';

  static String date(DateTime? d) => d == null ? '—' : _date.format(d);
  static String dateShort(DateTime? d) => d == null ? '—' : _dateShort.format(d);
  static String dateTime(DateTime? d) => d == null ? '—' : _dateTime.format(d);
  static String month(DateTime d) => _month.format(d);

  /// "2025-03" 形式のキー（月フィルタ用）
  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// "2025-03" -> "2025年3月"
  static String monthKeyLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    return '${parts[0]}年${int.tryParse(parts[1]) ?? parts[1]}月';
  }
}
