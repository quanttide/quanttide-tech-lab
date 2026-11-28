import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio_lab/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const LabApp());
  }

  testWidgets('判定卡：两个大数字与结论', (tester) async {
    await pumpApp(tester);
    expect(find.text('判定率'), findsOneWidget);
    expect(find.text('达标线'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget, reason: '判定率');
    expect(find.text('70%'), findsOneWidget, reason: '达标线');
    expect(find.textContaining('判定达标'), findsOneWidget);
  });

  testWidgets('明细默认收起，点开可复算', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('逐项加总'), findsNothing);

    await tester.tap(find.text('逐项明细 ▸'));
    await tester.pumpAndSettle();
    expect(find.textContaining('逐项加总'), findsOneWidget);

    // 可复算：明细里逐条贡献（形如「交付已提交  +0.45」）加总 == 判定率
    final partLines = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((d) => RegExp(r'[+-]\d\.\d{2}$').hasMatch(d))
        .toList();
    expect(partLines, hasLength(4));
    final sum = partLines
        .map((l) => double.parse(l.split(' ').last))
        .fold<double>(0, (s, v) => s + v);
    expect(sum, closeTo(demoRecords[0].judge!.rate, 1e-9));
  });

  testWidgets('班主视角：换主语不换数字', (tester) async {
    await pumpApp(tester);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.textContaining('报名学员：'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('班主视角 · 只读'), findsOneWidget);
    expect(find.textContaining('报名学员：'), findsNothing);
    expect(find.text('100%'), findsOneWidget, reason: '两个视角数字一致');
    expect(find.text('70%'), findsOneWidget, reason: '两个视角数字一致');
    expect(find.textContaining('判定达标'), findsOneWidget);
  });

  testWidgets('班主视角：有动作的阶段隐去动作', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('任务进行中学员'));
    await tester.pumpAndSettle();
    expect(find.text('提交交付物'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('提交交付物'), findsNothing);
    expect(find.textContaining('只读视角'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('提交交付物'), findsOneWidget);
  });
}
