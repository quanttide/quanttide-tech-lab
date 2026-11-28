import 'package:flutter_test/flutter_test.dart';
import 'package:studio_lab/game.dart';

void main() {
  final seed = 'lab-1';
  final scene = makeWeek(seed, 1);
  final state = initialLeader(seed);
  final lead = [...state.roster]
    ..sort((a, b) => elderScore(b).compareTo(elderScore(a)));

  group('游戏精髓', () {
    test('1 判定率是选择的函数：改选择，投影必变', () {
      final withMentor = forecast(
          sel: {'mentor'}, th: 3, state: state, scene: scene, lead: lead.first);
      final without = forecast(sel: {}, th: 3, state: state, scene: scene);
      expect(withMentor.p, isNot(without.p));
      expect(
          withMentor.parts.any((p) => p.source == 'mentor'), isTrue,
          reason: '带人开启时必须有带人行');
      expect(without.parts.any((p) => p.source == 'mentor'), isFalse);

      final tighter = forecast(
          sel: {'mentor'}, th: thMax, state: state, scene: scene,
          lead: lead.first);
      expect(tighter.p, isNot(withMentor.p), reason: '门槛变化也必变投影');
    });

    test('2 每行判定可追到来源动作', () {
      final f = forecast(
          sel: {'mentor', 'show', 'enroll'},
          th: 3,
          state: state,
          scene: scene,
          lead: lead.first,
          accepted: true);
      const known = {'state', 'mentor', 'show', 'th', 'enroll', 'tempt', 'cap'};
      expect(f.parts, isNotEmpty);
      for (final p in f.parts) {
        expect(known.contains(p.source), isTrue,
            reason: '「${p.label}」必须有来源');
      }
      expect(f.parts.any((p) => p.source == 'tempt'), isTrue,
          reason: '接了妥协必须出现代价行');
    });

    test('3 揭示可复现：同种子同结果', () {
      final f = forecast(
          sel: {'mentor'}, th: 3, state: state, scene: scene, lead: lead.first);
      final a = revealRolls(seed, 1, f);
      final b = revealRolls(seed, 1, f);
      expect(a, equals(b));
      expect(a.length, greaterThan(0));
    });

    test('4 真反转：学员环境逐项 == 班主选择与结果', () {
      final sel = {'mentor', 'enroll'};
      final f = forecast(
          sel: sel, th: 5, state: state, scene: scene, lead: lead.first);
      final applied = applyWeek(
          state: state,
          sel: sel,
          th: 5,
          scene: scene,
          rolls: revealRolls(seed, 1, f),
          lead: lead.first);
      final env = envFromLeader(
          sel: sel,
          th: 5,
          scene: scene,
          forecastResult: f,
          nextState: applied.next,
          lead: lead.first);
      expect(env.hasMentor, isTrue);
      expect(env.mentorName, lead.first.name);
      expect(env.gate, 5, reason: '学员的门槛 == 班主设的门槛');
      expect(env.over, f.over, reason: '过载 == 班主这周造出的过载');
      expect(env.rhythm, applied.next.rhythm, reason: '氛围 == 揭示后的氛围');
      expect(env.bestLv, scene.bestLv);
    });

    test('5 决定性分层与封顶：带人 0.28 压过噪音；没人带封顶 48%', () {
      // 班主侧：带人行是最大单项
      final f = forecast(
          sel: {'mentor'}, th: 3, state: state, scene: scene, lead: lead.first);
      final mentorPart =
          f.parts.firstWhere((p) => p.source == 'mentor');
      for (final p in f.parts) {
        if (p.source == 'mentor') continue;
        expect(mentorPart.value.abs(), greaterThanOrEqualTo(p.value.abs()),
            reason: '带人必须压过「${p.label}」');
      }

      // 学员侧：没人带且分数高 → 封顶 48%
      const envNoMentor = LearnerEnv(
          hasMentor: false, mentorName: '—', over: 0, gate: 4, bestLv: 4,
          rhythm: 95, temptRate: 0, temptTitle: '');
      final j = submitChance(
          env: envNoMentor,
          choice: const LearnerChoice(
              sel: {'seek'}, confidence: 100, stamina: 90, tribute: 0));
      expect(j.p, 0.48);
      expect(j.capped, isTrue);
      expect(j.parts.last.source, 'cap');
    });
  });

  test('提交推进状态：带人长名册、节奏按公式动', () {
    final f = forecast(
        sel: {'mentor'}, th: scene.bestLv, state: state, scene: scene,
        lead: lead.first);
    final applied = applyWeek(
        state: state,
        sel: {'mentor'},
        th: scene.bestLv,
        scene: scene,
        rolls: revealRolls(seed, 1, f),
        lead: lead.first);
    expect(applied.newElders, greaterThan(0), reason: '带人会带出新骨干');
    expect(applied.next.roster.length,
        state.roster.length - applied.lost + applied.newElders);
    expect(applied.next.quality, greaterThanOrEqualTo(state.quality));
  });
}
