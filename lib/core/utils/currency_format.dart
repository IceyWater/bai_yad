String formatPeso(double amount) {
  final decimals = amount % 1 == 0 ? 0 : 2;
  final parts = amount.toStringAsFixed(decimals).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '₱$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
}
