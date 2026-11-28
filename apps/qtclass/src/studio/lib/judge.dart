/// 评审判定（实验一）：逐项拆开摆出来，看的人能自己加总出结论。
///
/// 与河床工作台 store.judge() 同一规格——只用给定字段，无随机数，
/// 同一份数据任何时候判定一致。验收标准见 ../../ROADMAP.md。
library;

const double reviewPass = 0.70;

const requiredSurvey = [
  'self_position',
  'source',
  'research',
  'expectation',
  'leave_responsibility',
];

class JudgeResult {
  final List<(String, double)> parts;
  final double rate;
  final bool passed;

  const JudgeResult(this.parts, this.rate, this.passed);
}

JudgeResult judge({
  required bool hasDelivery,
  Map<String, String> answers = const {},
  bool schoolFilled = false,
  bool courseFilled = false,
  Duration? surveyDelay,
}) {
  final parts = <(String, double)>[];

  // 交付要件：没有交付物就没有评审
  parts.add((
    hasDelivery ? '交付已提交' : '交付未提交',
    hasDelivery ? 0.45 : 0.0,
  ));

  // 问卷要件：五道必填逐题计
  final filled = requiredSurvey
      .where((k) => (answers[k] ?? '').trim().isNotEmpty)
      .length;
  parts.add((
    '问卷要件 $filled/${requiredSurvey.length}',
    (0.30 * filled / requiredSurvey.length),
  ));

  // 报名信息：学校与意向课程
  final info = (schoolFilled ? 1 : 0) + (courseFilled ? 1 : 0);
  parts.add((
    info == 2 ? '报名信息完整' : '报名信息 $info/2',
    info == 2 ? 0.10 : 0.05 * info,
  ));

  // 问卷时效：报名到问卷 7 天内（旅程规则：超时转休眠）
  final timely =
      surveyDelay != null && surveyDelay <= const Duration(days: 7);
  parts.add((
    timely ? '问卷 7 天内完成' : '问卷超 7 天',
    timely ? 0.15 : 0.0,
  ));

  final rate = double.parse(
      parts.fold<double>(0, (sum, p) => sum + p.$2).toStringAsFixed(2));
  return JudgeResult(parts, rate, rate >= reviewPass);
}
