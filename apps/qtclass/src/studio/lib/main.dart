import 'dart:async';

import 'package:flutter/material.dart';

import 'game.dart';

const primary = Color(0xFF2F54EB);

void main() => runApp(const LabApp());

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮课堂工作台 · 氛围循环实验',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
      ),
      home: const LoopPage(),
    );
  }
}

class LoopPage extends StatefulWidget {
  const LoopPage({super.key});

  @override
  State<LoopPage> createState() => _LoopPageState();
}

class _LoopPageState extends State<LoopPage> {
  int _day = 1;
  final String _seed = 'lab-1';
  Scene _scene = makeWeek('lab-1', 1);
  LeaderState _leader = initialLeader('lab-1');

  // 班主侧选择
  final Set<String> _sel = {'mentor'};
  int _th = 3;
  bool _accepted = false;
  String? _leadId;

  // 揭示
  bool _revealing = false;
  List<bool> _rolls = const [];
  WeekResult? _result;
  bool _step2 = false, _step3 = false;

  // 学员侧
  int _tab = 0; // 0 班主的一周 / 1 学员的一周
  final Set<String> _lSel = {'seek'};
  double _confidence = 50, _stamina = 60;
  int _tribute = 0;
  bool? _lRoll;

  Elder? get _lead {
    final top = [..._leader.roster]
      ..sort((a, b) => elderScore(b).compareTo(elderScore(a)));
    if (top.isEmpty) return null;
    if (_leadId != null) {
      for (final e in top) {
        if (e.id == _leadId) return e;
      }
    }
    return top.first;
  }

  Forecast get _fc => forecast(
        sel: _sel,
        th: _th,
        state: _leader,
        scene: _scene,
        lead: _lead,
        accepted: _accepted,
      );

  LearnerEnv get _env => _result == null
      ? defaultEnv
      : envFromLeader(
          sel: _sel,
          th: _th,
          scene: _scene,
          forecastResult: _fc,
          nextState: _result!.next,
          lead: _lead,
          accepted: _accepted,
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('量潮课堂工作台 · 氛围循环实验'),
        actions: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('班主的一周')),
              ButtonSegment(value: 1, label: Text('学员的一周')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _tab == 0 ? _leaderBody(theme) : _learnerBody(theme),
      ),
    );
  }

  // ================= 班主的一周 =================

  List<Widget> _leaderBody(ThemeData theme) {
    final f = _fc;
    final tmp = temptations[_scene.temptIdx];
    return [
      // 场景
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Chip(label: Text('第 $_day 周')),
                const SizedBox(width: 8),
                Expanded(child: Text(_scene.rumorLine,
                    style: theme.textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 8),
              Text('预测本周最佳门槛 Lv${_scene.bestLv}（诊断折叠，点开看）',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              // 诱惑卡：妥协是选择，不是背景
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${tmp.icon} ${tmp.title}',
                        style: theme.textTheme.titleSmall),
                    Text(tmp.desc, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(children: [
                      ChoiceChip(
                        label: Text('收下 · ${tmp.shortcut.split(' · ').last}'),
                        selected: _accepted,
                        onSelected: (_) => setState(() => _accepted = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('拒绝，守住标准'),
                        selected: !_accepted,
                        onSelected: (_) => setState(() => _accepted = false),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),

      // 安排（选择在前）
      Text('本周安排', style: theme.textTheme.titleMedium),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final a in acts)
            FilterChip(
              avatar: Text(a.icon),
              label: Text('${a.name} · ${a.tag}'),
              selected: _sel.contains(a.id),
              onSelected: (_) => setState(() {
                _sel.contains(a.id) ? _sel.remove(a.id) : _sel.add(a.id);
              }),
            ),
        ],
      ),
      if (_sel.contains('mentor')) ...[
        const SizedBox(height: 8),
        Text('谁去带新人 · 质量×忠诚＝带人效果',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final e in ([..._leader.roster]
                  ..sort((a, b) => elderScore(b).compareTo(elderScore(a))))
                .take(4))
              ChoiceChip(
                label: Text(
                    '${e.name} ×${elderScore(e).toStringAsFixed(2)}'),
                selected: (_lead?.id ?? '') == e.id,
                onSelected: (_) => setState(() => _leadId = e.id),
              ),
          ],
        ),
      ],
      const SizedBox(height: 8),
      Row(children: [
        const Text('门槛 Lv'),
        Expanded(
          child: Slider(
            value: _th.toDouble(),
            min: thMin.toDouble(),
            max: thMax.toDouble(),
            divisions: thMax - thMin,
            label: 'Lv$_th',
            onChanged: _revealing
                ? null
                : (v) => setState(() => _th = v.round()),
          ),
        ),
        Text('Lv$_th', style: theme.textTheme.titleSmall),
      ]),
      const SizedBox(height: 8),

      // 投影：判定是选择的函数，每行可追到动作
      Card(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${(f.p * 100).round()}%',
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('交作业率投影 · ${f.nb} 位新人 → 预计 ${f.expected} 人交',
                        style: theme.textTheme.bodySmall)),
              ]),
              const SizedBox(height: 8),
              for (final part in f.parts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${part.label}  ${part.value >= 0 ? '+' : ''}'
                    '${part.value.toStringAsFixed(3)}'
                    '  〔${_sourceName(part.source)}〕',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                '改任意选择，投影立刻重算——每一行都追得到你干的事。',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),

      if (!_revealing && _result == null)
        FilledButton.icon(
          onPressed: () => _commitWeek(),
          icon: const Icon(Icons.play_arrow),
          label: Text('提交本周安排（${_sel.length} 项 + 门槛 Lv$_th）'),
        ),

      if (_revealing) _revealPanel(theme),
      if (_result != null && !_revealing) _resultPanel(theme),
    ];
  }

  String _sourceName(String? s) => switch (s) {
        'mentor' => '带人',
        'show' => '成品展',
        'th' => '门槛',
        'enroll' => '招生',
        'tempt' => '妥协',
        'cap' => '封顶',
        'seek' => '找人带',
        'env' => '他的处境',
        _ => '班级状态',
      };

  // ---- 揭示：传言 → 门槛对比 → 逐人掷 ----

  void _commitWeek() {
    setState(() {
      _revealing = true;
      _rolls = revealRolls(_seed, _day, _fc);
      _result = null;
      _step2 = false;
      _step3 = false;
    });
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _step2 = true);
    });
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _step3 = true);
    });
    Timer(const Duration(milliseconds: 1500 + 90 * 26 + 600), () {
      if (!mounted) return;
      setState(() {
        _result = applyWeek(
          state: _leader,
          sel: _sel,
          th: _th,
          scene: _scene,
          rolls: _rolls,
          lead: _lead,
          accepted: _accepted,
        );
        _revealing = false;
      });
    });
  }

  Widget _revealPanel(ThemeData theme) {
    final f = _fc;
    final shown = _step3 ? _rolls.length : (_step2 ? 0 : 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step2
                  ? '传言${_scene.rumorTrue ? '是真的' : '是假的'}；'
                      '你的 Lv$_th 对上预测最佳 Lv${_scene.bestLv}'
                      '${_th == _scene.bestLv ? '（设对了）' : '（差 ${(_th - _scene.bestLv).abs()} 级）'}'
                  : '传言未揭晓…',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < (shown > 0 ? _rolls.length : 0); i++)
                  Text(
                    _rolls[i] ? '✓' : '✗',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _rolls[i]
                          ? const Color(0xFF12A66A)
                          : const Color(0xFFF5222D),
                    ),
                  ),
              ],
            ),
            if (shown > 0)
              Text('按 Lv$_th 门槛，${f.nb} 位新人进班，逐人判定…',
                  style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _resultPanel(ThemeData theme) {
    final r = _result!;
    final f = _fc;
    final actualRate = f.nb > 0 ? r.got / f.nb : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('${(actualRate * 100).round()}%',
                  style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF12A66A))),
              const SizedBox(width: 10),
              Text('${(f.p * 100).round()}%',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    '实际交作业率 · ${r.got}/${f.nb} 人交了（投影 ${(f.p * 100).round()}%）',
                    style: theme.textTheme.bodySmall),
              ),
            ]),
            const Divider(),
            Text('这一周的代价与进账', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('节奏 ${_leader.rhythm.round()} → ${r.next.rhythm.round()}'
                '（${r.rhythmDelta >= 0 ? '+' : ''}${r.rhythmDelta.round()}）'),
            Text('优质率 ${( _leader.quality * 100).round()}% → '
                '${(r.next.quality * 100).round()}%'),
            Text('疲惫 ${_leader.fatigue.round()} → ${r.next.fatigue.round()}'),
            Text('耐心 ${_leader.patience.round()} → ${r.next.patience.round()}'
                '（${patienceDelta(sel: _sel, th: _th, state: _leader, scene: _scene, accepted: _accepted) >= 0 ? '+' : ''}'
                '${patienceDelta(sel: _sel, th: _th, state: _leader, scene: _scene, accepted: _accepted).round()}）'),
            Text('口碑 ${_leader.rep.round()} → ${r.next.rep.round()}'),
            Text('名册 ${_leader.roster.length} → ${r.next.roster.length} 人'
                '（流失 ${r.lost}，新进 ${r.newElders}）'),
            const SizedBox(height: 12),
            Row(children: [
              FilledButton(
                onPressed: () => setState(() {
                  _day += 1;
                  _scene = makeWeek(_seed, _day);
                  _leader = _result!.next;
                  _result = null;
                  _rolls = const [];
                  _accepted = false;
                  _leadId = null;
                  _lRoll = null;
                }),
                child: Text('下一周（第 ${_day + 1} 周）'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => setState(() => _tab = 1),
                child: const Text('切到学员的一周 →'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ================= 学员的一周（真反转）=================

  List<Widget> _learnerBody(ThemeData theme) {
    final env = _env;
    final choice = LearnerChoice(
      sel: _lSel,
      confidence: _confidence,
      stamina: _stamina,
      tribute: _tribute,
    );
    final j = submitChance(env: env, choice: choice);
    final fromLeader = _result != null;

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('他的处境 · 逐项来自班主这一周的选择',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text('带人：${env.hasMentor ? '有（${env.mentorName}）' : '没人带'}'
                  '  ·  门槛 Lv${env.gate}（最佳 Lv${env.bestLv}）'
                  '  ·  过载 ${env.over} 人'),
              Text('班级氛围 ${env.rhythm.round()}'
                  '${env.temptRate != 0 ? '  ·  班主接了「${env.temptTitle}」，代价也落到你头上' : ''}'),
              if (!fromLeader)
                Text('（还没玩过班主的一周——这是典型班主的缺省环境；'
                    '玩一周再回来，处境就是你自己的选择）',
                    style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        _stat(theme, '信心', _confidence),
        const SizedBox(width: 12),
        _stat(theme, '心力', _stamina),
        const SizedBox(width: 12),
        _stat(theme, '传承', _tribute.toDouble()),
      ]),
      const SizedBox(height: 12),
      Text('他的抉择', style: theme.textTheme.titleMedium),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilterChip(
          avatar: const Text('🙋'),
          label: const Text('找人带我 · 关键'),
          selected: _lSel.contains('seek'),
          onSelected: (_) => setState(() {
            _lSel.contains('seek') ? _lSel.remove('seek') : _lSel.add('seek');
            _lRoll = null;
          }),
        ),
        FilterChip(
          avatar: const Text('✍️'),
          label: Text('交出我的成品 · 信心${_confidence < 35 ? '不足' : '够'}'),
          selected: _lSel.contains('submit'),
          onSelected: _confidence >= 35
              ? (_) => setState(() {
                    _lSel.add('submit');
                            _lRoll = revealSubmit('$_seed|$_day', j);
                    if (_lRoll == true) {
                      _confidence = clamp(_confidence + 6, 0, 100);
                    } else {
                      _confidence = clamp(_confidence - 4, 0, 100);
                    }
                  })
              : null,
        ),
        FilterChip(
          avatar: const Text('🌱'),
          label: const Text('去带一个刚来的人 · 心力 -8 · 信心 +12 · 传承 +1'),
          selected: false,
          onSelected: _stamina >= 10
              ? (_) => setState(() {
                    _stamina = clamp(_stamina - 8, 0, 100);
                    _confidence = clamp(_confidence + 12, 0, 100);
                    _tribute += 1;
                  })
              : null,
        ),
      ]),
      const SizedBox(height: 12),
      Card(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${(j.p * 100).round()}%',
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('交成品的把握 · 同一个式子，换你这侧的处境',
                        style: theme.textTheme.bodySmall)),
              ]),
              const SizedBox(height: 8),
              for (final part in j.parts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${part.label}  ${part.value >= 0 ? '+' : ''}'
                    '${part.value.toStringAsFixed(3)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (_lRoll != null) ...[
        const SizedBox(height: 10),
        Text(
          _lRoll! ? '✓ 成品交出去了，被看见了。' : '✗ 这次没交成——信心掉了，再来。',
          style: theme.textTheme.titleMedium?.copyWith(
              color: _lRoll!
                  ? const Color(0xFF12A66A)
                  : const Color(0xFFF5222D)),
        ),
      ],
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => setState(() => _tab = 0),
        child: const Text('← 回班主的一周'),
      ),
    ];
  }

  Widget _stat(ThemeData theme, String label, double v) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v.round().toString(),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
