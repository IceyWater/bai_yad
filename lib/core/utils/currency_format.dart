String formatPeso(double amount) {
  final centavos = (amount.abs() * 100 + 1e-7).round();
  final wholeValue = centavos ~/ 100;
  final fraction = centavos % 100;
  final whole = wholeValue.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  final decimals = fraction == 0
      ? ''
      : '.${fraction.toString().padLeft(2, '0')}';
  final sign = amount < 0 ? '-' : '';
  return '$sign₱$whole$decimals';
}
