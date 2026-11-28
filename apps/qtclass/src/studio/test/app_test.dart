import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio_lab/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    // 高视口：整周的场景、安排、投影、提交按钮同屏可见（列表不折叠）
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const LabApp());
  }

  String bigNumber(WidgetTester tester) {
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((d) => RegExp(r'^\d+%$').hasMatch(d),
            orElse: () => '');
  }

  testWidgets('选择在前：撤掉带人，投影立刻变、带人行消失', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('（决定性）'), findsOneWidget,
        reason: '默认带人，投影必须有带人行');
    expect(find.textContaining('〔带人〕'), findsOneWidget,
        reason: '带人行必须标注来源动作');
    final before = bigNumber(tester);
    expect(before, isNotEmpty);

    await tester.tap(find.text('老人带新人 · 交作业率 +28%'));
    await tester.pumpAndSettle();

    expect(find.textContaining('（决定性）'), findsNothing);
    expect(bigNumber(tester), isNot(before), reason: '改选择投影必变');
  });

  testWidgets('提交 → 揭示 → 这一周的代价与进账', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.textContaining('提交本周安排'));
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();

    expect(find.textContaining('实际交作业率'), findsOneWidget);
    expect(find.textContaining('名册'), findsOneWidget);
    expect(find.text('下一周（第 2 周）'), findsOneWidget);
  });

  testWidgets('真反转：学员处境逐项来自主管选择', (tester) async {
    await pumpApp(tester);
    // 先玩一周（默认选择：带人 + 门槛 Lv3）
    await tester.tap(find.textContaining('提交本周安排'));
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();

    await tester.tap(find.text('切到学员的一周 →'));
    await tester.pumpAndSettle();

    expect(find.textContaining('逐项来自班主这一周的选择'), findsOneWidget);
    expect(find.textContaining('带人：有（'), findsOneWidget,
        reason: '学员看到的带人 == 班主选了带人');
    expect(find.textContaining('门槛 Lv3（最佳'), findsOneWidget,
        reason: '学员的门槛 == 班主设的 Lv3');
    expect(find.textContaining('交成品的把握'), findsOneWidget);
  });
}
