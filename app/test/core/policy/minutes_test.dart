import 'package:family_os/core/domain/minutes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Minutes', () {
    test('zero is zero', () {
      expect(Minutes.zero.inMinutes, 0);
      expect(Minutes.zero.isZero, isTrue);
    });

    test('factory accepts non-negative values', () {
      expect(Minutes(0).inMinutes, 0);
      expect(Minutes(15).inMinutes, 15);
    });

    test('factory rejects negative values', () {
      expect(() => Minutes(-1), throwsArgumentError);
    });

    test('addition', () {
      expect(Minutes(10) + Minutes(5), Minutes(15));
      expect(Minutes.zero + Minutes(3), Minutes(3));
    });

    test('subtraction', () {
      expect(Minutes(10) - Minutes(4), Minutes(6));
      expect(Minutes(5) - Minutes(5), Minutes.zero);
    });

    test('subtraction underflow throws', () {
      expect(() => Minutes(3) - Minutes(4), throwsArgumentError);
    });

    test('comparison operators', () {
      expect(Minutes(1) < Minutes(2), isTrue);
      expect(Minutes(2) <= Minutes(2), isTrue);
      expect(Minutes(3) > Minutes(2), isTrue);
      expect(Minutes(3) >= Minutes(3), isTrue);
      expect(Minutes(1).compareTo(Minutes(2)), lessThan(0));
      expect(Minutes(2).compareTo(Minutes(2)), 0);
    });

    test('equality and hashCode', () {
      expect(Minutes(7), Minutes(7));
      expect(Minutes(7), isNot(Minutes(8)));
      expect(Minutes(7).hashCode, Minutes(7).hashCode);
    });

    test('toString', () {
      expect(Minutes(9).toString(), 'Minutes(9)');
    });
  });
}
