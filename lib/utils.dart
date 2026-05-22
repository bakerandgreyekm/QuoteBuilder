String formatINR(double amount) {
  final int v = amount.round();
  final String s = v.toString();
  final int len = s.length;
  if (len <= 3) return '₹$s';
  final String last3 = s.substring(len - 3);
  final String rest = s.substring(0, len - 3);
  final buf = StringBuffer();
  for (int i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '₹$buf,$last3';
}
