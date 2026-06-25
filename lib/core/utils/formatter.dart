import 'package:intl/intl.dart';

final _manYenFormatter = NumberFormat('#,###');
final _yenFormatter = NumberFormat('#,###');

String formatManYen(int amount) => '${_manYenFormatter.format(amount)}万円';

/// 万円単位の月額を「¥200,000」形式で表示
String formatYenMonthlyFromMan(num amountMan) {
  final yen = (amountMan * 10000).round();
  return '¥${_yenFormatter.format(yen)}';
}

/// 万円単位の総額を「¥2,376,000」形式で表示
String formatYenFromMan(int amountMan) =>
    '¥${_yenFormatter.format(amountMan * 10000)}';

String formatYen(int yen) => '¥${_yenFormatter.format(yen)}';

String formatGap(int gap) {
  if (gap > 0) return '▲ ${formatManYen(gap)}';
  if (gap < 0) return '▼ ${formatManYen(gap.abs())}';
  return 'ちょうど';
}

String formatDate(DateTime date) =>
    DateFormat('yyyy/MM/dd').format(date);
