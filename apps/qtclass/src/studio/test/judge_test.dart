import 'package:flutter_test/flutter_test.dart';
import 'package:studio_lab/judge.dart';

void main() {
  group('judge：确定性与可复算', () {
    final fullAnswers = {
      'self_position': '愿意踏实地学',
      'source': 'GitHub',
      'research': '读过开源章程',
      'expectation': '建立完整认知',
      'leave_responsibility': '交接任务',
    };

    test('全量交付满分且可复算', () {
      final j = judge(
        hasDelivery: true,
        answers: fullAnswers,
        schoolFilled: true,
        courseFilled: true,
        surveyDelay: const Duration(days: 2),
      );
      expect(j.parts.fold<double>(0, (s, p) => s + p.$2), closeTo(j.rate, 1e-9));
      expect(j.rate, 1.0);
      expect(j.passed, isTrue);
    });

    test('缺交付不及格', () {
      final j = judge(hasDelivery: true == false, answers: fullAnswers,
          schoolFilled: true, courseFilled: true,
          surveyDelay: const Duration(days: 2));
      expect(j.passed, isFalse);
      expect(j.rate, lessThanOrEqualTo(0.55));
    });

    test('问卷缺一题扣分精确', () {
      final answers = {...fullAnswers}..remove('research');
      final j = judge(
        hasDelivery: true,
        answers: answers,
        schoolFilled: true,
        courseFilled: true,
        surveyDelay: const Duration(days: 2),
      );
      expect(j.rate, closeTo(1.0 - 0.30 / 5, 1e-9));
      expect(j.passed, isTrue); // 0.94 ≥ 0.70
    });

    test('问卷超 7 天丢时效分', () {
      final j = judge(
        hasDelivery: true,
        answers: fullAnswers,
        schoolFilled: true,
        courseFilled: true,
        surveyDelay: const Duration(days: 15),
      );
      expect(j.rate, closeTo(0.85, 1e-9));
      expect(j.passed, isTrue);
    });

    test('同一份数据判定一致', () {
      JudgeResult make() => judge(
            hasDelivery: true,
            answers: fullAnswers,
            schoolFilled: true,
            courseFilled: true,
            surveyDelay: const Duration(days: 2),
          );
      expect(make().rate, make().rate);
      expect(make().parts, make().parts);
    });
  });
}
