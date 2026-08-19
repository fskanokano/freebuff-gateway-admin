import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_admin/widgets/common.dart';

void main() {
  group('maskKey', () {
    test('空/空值返回 —', () {
      expect(maskKey(null), '—');
      expect(maskKey(''), '—');
    });

    test('短密钥（≤6）首字符+***', () {
      expect(maskKey('abc'), 'a***');
      expect(maskKey('abcdef'), 'a***');
    });

    test('长密钥前3…后3', () {
      expect(maskKey('sk-1234567890'), 'sk-…890');
    });
  });

  group('formatCount', () {
    test('千分位', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
      expect(formatCount(1000), '1,000');
      expect(formatCount(1234567), '1,234,567');
    });

    test('负数', () {
      expect(formatCount(-1234), '-1,234');
    });
  });

  group('formatCompact', () {
    test('亿/万/小数字', () {
      expect(formatCompact(123456789), '1.2亿');
      expect(formatCompact(12345), '1.2万');
      expect(formatCompact(999), '999');
    });

    test('边界 1 亿 / 1 万', () {
      expect(formatCompact(100000000), '1.0亿');
      expect(formatCompact(10000), '1.0万');
    });
  });

  group('formatMoney', () {
    test('null → —', () {
      expect(formatMoney(null), '—');
    });

    test('0 → \$0', () {
      expect(formatMoney(0), '\$0');
    });

    test('小于 1 保留两位小数', () {
      expect(formatMoney(0.5), '\$0.50');
      expect(formatMoney(0.02), '\$0.02');
    });

    test('大额走紧凑格式', () {
      expect(formatMoney(12345), '\$1.2万');
      expect(formatMoney(123456789), '\$1.2亿');
    });
  });

  group('countryFlag', () {
    test('国家代码 → 国旗 emoji', () {
      expect(countryFlag('us'), '🇺🇸');
      expect(countryFlag('CN'), '🇨🇳');
    });

    test('无效输入返回空串', () {
      expect(countryFlag(null), '');
      expect(countryFlag(''), '');
      expect(countryFlag('USA'), '');
      expect(countryFlag('u1'), '');
    });
  });
}
