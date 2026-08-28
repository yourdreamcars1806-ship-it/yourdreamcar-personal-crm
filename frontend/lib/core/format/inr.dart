String formatInrCompact(num value) {
  final n = value.abs();
  if (n >= 10000000) {
    final v = n / 10000000;
    return '₹${v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(2)} Cr';
  }
  if (n >= 100000) {
    final v = n / 100000;
    return '₹${v >= 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(2)} L';
  }
  return formatInr(value);
}

String formatInr(num value) {
  final n = value.round().abs();
  final s = n.toString();
  if (s.length <= 3) {
    return '₹ $s';
  }
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) {
    parts.insert(0, rest);
  }
  return '₹ ${parts.join(',')},$last3';
}

String formatKm(num km) {
  final n = km.round();
  if (n >= 100000) {
    return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)} Lakh km';
  }
  if (n >= 1000) {
    final s = n.toString();
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    return '$rest,$last3 km';
  }
  return '$n km';
}
