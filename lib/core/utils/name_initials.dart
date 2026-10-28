String nameInitials(String name, {String emptyValue = 'AN'}) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return emptyValue;
  if (parts.length == 1) {
    final firstName = parts.first;
    return firstName.substring(0, firstName.length > 1 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
