import 'package:intl/intl.dart';

final _manYenFormatter = NumberFormat('#,###');

String formatManYen(int amount) => '${_manYenFormatter.format(amount)}万円';

String formatGap(int gap) {
  if (gap > 0) return '▲ ${formatManYen(gap)}';
  if (gap < 0) return '▼ ${formatManYen(gap.abs())}';
  return 'ちょうど';
}

String formatDate(DateTime date) =>
    DateFormat('yyyy/MM/dd').format(date);
