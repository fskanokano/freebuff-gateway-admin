import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_admin/l10n/app_localizations_en.dart';
import 'package:gateway_admin/l10n/app_localizations_zh.dart';
import 'package:gateway_admin/l10n/l10n_ext.dart';

void main() {
  final zh = AppLocalizationsZh('zh');
  final en = AppLocalizationsEn('en');

  test('statusLabel 中英文映射', () {
    expect(zh.statusLabel('ok'), '正常');
    expect(zh.statusLabel('depleted'), '额度耗尽');
    expect(zh.statusLabel('maint'), '维护中');
    expect(zh.statusLabel('unknown'), 'unknown');
    expect(en.statusLabel('ok'), 'Healthy');
    expect(en.statusLabel('down'), 'Down');
  });

  test('relativeTime 处理 null', () {
    expect(zh.relativeTime(null), '—');
    expect(en.relativeTime(null), '—');
  });

  test('compact 中文万/亿 与 英文 K/M', () {
    expect(zh.compact(12345), '1.2万');
    expect(zh.compact(123456789), '1.2亿');
    expect(en.compact(1500), '1.5K');
    expect(en.compact(2500000), '2.5M');
  });

  test('money 金额格式化', () {
    expect(zh.money(null), '—');
    expect(zh.money(0), '\$0');
    expect(zh.money(0.5), '\$0.50');
    expect(zh.money(12345), '\$1.2万');
    expect(en.money(12345), '\$12.3K');
  });
}
