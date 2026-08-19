import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_admin/main.dart';
import 'package:gateway_admin/pages/connect_page.dart';
import 'package:gateway_admin/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  setUp(() {
    // 测试环境需要 mock SharedPreferences（AppState 异步读取本地存储）
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    return ShadApp(
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      home: child,
    );
  }

  testWidgets('连接页渲染表单与按钮', (tester) async {
    final state = AppState();
    await tester.pumpWidget(wrap(ConnectPage(state: state)));
    await tester.pumpAndSettle();

    expect(find.text('FreeBuff 网关管理'), findsOneWidget);
    expect(find.byType(ShadInput), findsNWidgets(2));
    expect(find.text('连接并验证'), findsOneWidget);
  });

  testWidgets('空表单校验拦截提交', (tester) async {
    final state = AppState();
    await tester.pumpWidget(wrap(ConnectPage(state: state)));
    await tester.pumpAndSettle();

    // 不输入任何内容直接点连接（URL 有默认 https:// 占位，密钥为空）
    await tester.tap(find.text('连接并验证'));
    await tester.pumpAndSettle();

    expect(find.text('请输入密钥'), findsOneWidget);
  });

  testWidgets('非法地址校验', (tester) async {
    final state = AppState();
    await tester.pumpWidget(wrap(ConnectPage(state: state)));
    await tester.pumpAndSettle();

    final fields = find.byType(ShadInput);
    await tester.enterText(fields.first, 'gw.example.com');
    await tester.enterText(fields.at(1), 'key');
    await tester.tap(find.text('连接并验证'));
    await tester.pumpAndSettle();

    expect(find.text('需以 http:// 或 https:// 开头'), findsOneWidget);
  });

  testWidgets('主应用可构建（连接页路由）', (tester) async {
    await tester.pumpWidget(const FreeBuffApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    // 未配置时进入连接页
    expect(find.text('FreeBuff 网关管理'), findsOneWidget);
  });
}
