import 'package:flutter_test/flutter_test.dart';
import 'package:bai_yad/core/utils/currency_format.dart';

void main() {
  test('formats peso values with centavo precision and grouping', () {
    expect(formatPeso(1234.5), '₱1,234.50');
    expect(formatPeso(1234.567), '₱1,234.57');
    expect(formatPeso(99_999_999.99), '₱99,999,999.99');
    expect(formatPeso(1200), '₱1,200');
  });
}