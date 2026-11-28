/// 氛围局机制的最小移植（实验室实验，取自 apps/qtclass/atmosphere.html）：
/// 选择在前 → 判定是选择的函数（每行可追到动作）→ 提交 → 逐人揭示 →
/// 学员侧环境由班主侧选择生成（真反转）。
///
/// 实验边界：现金、班规、阶段、飞轮不在本实验（留氛围局本体）；
/// 判定与状态公式照抄原作，只去掉与边界相关的项。
library;

// ---------- RNG（mulberry32 + hashStr，照抄原作位运算） ----------

int _imul(int a, int b) =>
    ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF;

int hashStr(String s) {
  var h = (1779033703 ^ s.length) & 0xFFFFFFFF;
  for (final ch in s.codeUnits) {
    h = _imul(h ^ ch, 3432918353);
    h = ((h << 13) | (h >>> 19)) & 0xFFFFFFFF;
  }
  return h;
}

/// 返回 0..1 的伪随机流。
double Function() mulberry32(int seed) {
  var a = seed & 0xFFFFFFFF;
  return () {
    a = (a + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _imul(a ^ (a >>> 15), 1 | a);
    t = ((_tAdd(t, _imul(t ^ (t >>> 7), 61 | t)))) ^ t;
    t = t & 0xFFFFFFFF;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 4294967296;
  };
}

int _tAdd(int a, int b) => (a + b) & 0xFFFFFFFF;

double clamp(num v, num lo, num hi) =>
    v < lo ? lo.toDouble() : (v > hi ? hi.toDouble() : v.toDouble());

// ---------- 常数（照抄） ----------

const thMin = 2, thMax = 6, defTh = 3;

// ---------- 动作（ACTS，照抄原作文案与标签） ----------

class Act {
  final String id, grp, icon, name, tag, desc;
  const Act(this.id, this.grp, this.icon, this.name, this.tag, this.desc);
}

const acts = [
  Act('screen', '供给', '🔍', '评审筛人', '优质率 +10%', '慢性子，回报滞后'),
  Act('enroll', '供给', '📣', '开放免费通道', '新人 +9 · 耐心 -4', '来人快，也更磨人'),
  Act('mentor', '杠杆', '🤝', '老人带新人', '交作业率 +28%', '新人是被老人带走的'),
  Act('show', '杠杆', '🎬', '成品展 / 周复盘', '节奏 +5 · 耐心 +2', '被看见，才有人跟'),
  Act('project', '维护', '🧩', '给老人真实项目', '疲惫 -12 · 耐心 +3', '产出被用掉，才留人'),
  Act('rest', '维护', '☕', '暂停招生休整', '疲惫 -10 · 耐心 +4', '让老人喘口气'),
];

// ---------- 诱惑卡（照抄） ----------

class Temptation {
  final String id, icon, title, shortcut, desc;
  final double pat;
  final double? rate;
  final int rep;
  final int nb, over, overExtra;
  const Temptation({
    required this.id,
    required this.icon,
    required this.title,
    required this.shortcut,
    required this.desc,
    required this.pat,
    this.rate,
    this.rep = 0,
    this.nb = 0,
    this.over = 0,
    this.overExtra = 0,
  });
}

const temptations = [
  Temptation(
      id: 'paid', icon: '💰', title: '有人愿意付费插班',
      shortcut: '收下 · 现金 +¥8,000',
      desc: '收下立刻有钱，但同班不同标准，氛围就被开了口子。',
      pat: -12, rep: -3, over: 2),
  Temptation(
      id: 'record', icon: '📼', title: '有人劝你改成录播课',
      shortcut: '改录播 · 耐心 +8',
      desc: '省人力，但新人接不上老人的节奏。',
      pat: 8, rate: -0.12),
  Temptation(
      id: 'viral', icon: '📣', title: '渠道说能一次拉 30 人',
      shortcut: '拉进来 · 新人 +15',
      desc: '班立刻热闹，但过载会压垮交作业率。',
      pat: -8, nb: 15, overExtra: 6),
  Temptation(
      id: 'lower', icon: '🔓', title: '有人劝你把门槛降到最低',
      shortcut: '降门槛 · 人人可进',
      desc: '谁都能进，但没人真动手。',
      pat: -6, rate: -0.10),
  Temptation(
      id: 'cert', icon: '🎓', title: '合作方要你发"结业保证"',
      shortcut: '答应 · 口碑 +6 现金 +¥3,000',
      desc: '短期好看，但这是你一直避开的那条线。',
      pat: -10, rep: 6),
];

// ---------- 骨干名册（照抄） ----------

const elderNames = [
  '阿灶', '阿灯', '阿满', '小木', '小水', '小火', '晴晴', '雨滴', '小风',
  '串串', '毛肚', '灯笼', '阿猫', '阿狗', '阿雀', '金锅', '夜珠', '传灯',
];

class ElderStyle {
  final String n;
  final int care, loyal;
  const ElderStyle(this.n, this.care, this.loyal);
}

const elderStyles = [
  ElderStyle('严', 6, -4),
  ElderStyle('稳', 0, 4),
  ElderStyle('松', -5, 5),
];

class Elder {
  final String id, name, style;
  final int care, loyal;
  final double drift;
  const Elder({
    required this.id,
    required this.name,
    required this.style,
    required this.care,
    required this.loyal,
    required this.drift,
  });

  Elder copyWith({int? care, int? loyal, double? drift}) => Elder(
        id: id,
        name: name,
        style: style,
        care: care ?? this.care,
        loyal: loyal ?? this.loyal,
        drift: drift ?? this.drift,
      );
}

Elder makeElder(int i, double Function() rnd) {
  final st = elderStyles[(rnd() * 3).floor() % 3];
  return Elder(
    id: 'e$i',
    name: elderNames[i % elderNames.length],
    style: st.n,
    care: clamp((94 + rnd() * 14).round() + st.care, 80, 118).round(),
    loyal: clamp((60 + rnd() * 22).round() + st.loyal, 35, 96).round(),
    drift: 0,
  );
}

/// 带人效果 = 质量 ×（0.9 + 忠诚×0.002）×（1 − 带歪）
double elderScore(Elder e) =>
    (e.care / 100) * (0.9 + e.loyal * 0.002) * (1 - (0.3 < e.drift ? 0.3 : e.drift));

// ---------- 一周场景（照抄 makeWeek） ----------

class Scene {
  final bool rumorTrue;
  final String rumorLine;
  final int bestLv;
  final int temptIdx;
  const Scene({
    required this.rumorTrue,
    required this.rumorLine,
    required this.bestLv,
    required this.temptIdx,
  });
}

const rumorLines = [
  '听说这周大家都卷起来了',
  '群里说这周没人想动手',
  '有人说门槛一高人就散了',
  '老学员说这周会爆满',
];

Scene makeWeek(String seed, int day, {int cycle = 0}) {
  final rnd = mulberry32(hashStr('$seed|$day|$cycle'));
  final rumorTrue = rnd() < 0.7;
  final rumorUp = ((rumorTrue ? 1 : -1) * (rnd() < 0.6 ? 1 : -1)) > 0;
  return Scene(
    rumorTrue: rumorTrue,
    rumorLine: rumorUp ? rumorLines[(rnd() * 4).floor() % 4] : rumorLines[(rnd() * 4).floor() % 4],
    bestLv: thMin + (rnd() * (thMax - thMin + 1)).floor(),
    temptIdx: (rnd() * temptations.length).floor(),
  );
}

// ---------- 班主状态 ----------

class LeaderState {
  final double rhythm, quality, fatigue, patience, rep;
  final List<Elder> roster;
  const LeaderState({
    required this.rhythm,
    required this.quality,
    required this.fatigue,
    required this.patience,
    required this.rep,
    required this.roster,
  });

  LeaderState copyWith({
    double? rhythm,
    double? quality,
    double? fatigue,
    double? patience,
    double? rep,
    List<Elder>? roster,
  }) =>
      LeaderState(
        rhythm: rhythm ?? this.rhythm,
        quality: quality ?? this.quality,
        fatigue: fatigue ?? this.fatigue,
        patience: patience ?? this.patience,
        rep: rep ?? this.rep,
        roster: roster ?? this.roster,
      );
}

/// 演示初值：氛围班中段（节奏 48、骨干 6 与阶段表一致）
LeaderState initialLeader(String seed) {
  final rnd = mulberry32(hashStr('$seed|roster'));
  return LeaderState(
    rhythm: 48,
    quality: 0.55,
    fatigue: 42,
    patience: 60,
    rep: 30,
    roster: [for (var i = 0; i < 6; i++) makeElder(i, rnd)],
  );
}

// ---------- 判定（forecast 照抄；每行带来源动作） ----------

class Part {
  final String label;
  final double value;
  final String? source; // 来源动作 id / 'th' / 'state' / 'tempt'
  const Part(this.label, this.value, this.source);
}

class Forecast {
  final int nb, cap, over;
  final double p;
  final int expected;
  final bool capped;
  final List<Part> parts;
  const Forecast({
    required this.nb,
    required this.cap,
    required this.over,
    required this.p,
    required this.expected,
    required this.capped,
    required this.parts,
  });
}

/// sel = 动作 id 集合；lead = 选中的带人骨干；th = 门槛。
Forecast forecast({
  required Set<String> sel,
  required int th,
  required LeaderState state,
  required Scene scene,
  Elder? lead,
  bool accepted = false,
}) {
  final tmp = temptations[scene.temptIdx];
  var nb = 1 +
      3 +
      (state.rep / 30).floor() +
      (sel.contains('enroll') ? 9 : 0) +
      (sel.contains('screen') ? 2 : 0) -
      (sel.contains('rest') ? 5 : 0) -
      (th - defTh) +
      (accepted && tmp.nb > 0 ? tmp.nb : 0);
  if (nb < 1) nb = 1;

  final cap = state.roster.length < 2 ? 2 : state.roster.length;
  var over = nb - cap;
  if (over < 0) over = 0;
  if (accepted && tmp.over > 0) over += tmp.over;
  if (accepted && tmp.overExtra > 0) over += tmp.overExtra;

  final thFit =
      th == scene.bestLv ? 0.05 : -0.035 * (th - scene.bestLv).abs();

  final mentorOn = sel.contains('mentor') && lead != null;
  final mentorMul = mentorOn ? elderScore(lead) : 1.0;

  final parts = <Part>[
    Part('班级节奏（${state.rhythm.round()}）', state.rhythm * 0.002, 'state'),
    Part('优质率（${(state.quality * 100).round()}%）', state.quality * 0.07, 'state'),
    if (mentorOn)
      Part('老人带新人 · ${lead.name}（决定性）', 0.28 * mentorMul, 'mentor'),
    if (sel.contains('show')) const Part('成品展 / 周复盘', 0.04, 'show'),
    Part('门槛设对（Lv$th）', thFit, 'th'),
    Part('新人过载（超 $over 人）', -clamp(over * 0.045, 0, 0.45), 'enroll'),
    Part(
        '老人疲惫（${state.fatigue.round()}）',
        state.fatigue > 60
            ? -0.12
            : (state.fatigue > 40 ? -0.05 : 0.0),
        'state'),
    Part('门槛过高压意愿', -(th - defTh) * 0.025, 'th'),
  ];
  if (accepted && tmp.rate != null) {
    parts.add(Part('妥协的代价（${tmp.title}）', tmp.rate!, 'tempt'));
  }

  var p = 0.26;
  for (final x in parts) {
    p += x.value;
  }
  p = clamp(p, 0.10, 0.94);

  var capped = false;
  if (!mentorOn && p > 0.48) {
    p = 0.48;
    capped = true;
    parts.add(const Part('⚠ 没人带，交作业率封顶', 0, 'cap'));
  }

  return Forecast(
    nb: nb,
    cap: cap,
    over: over,
    p: p,
    expected: (nb * p).round(),
    capped: capped,
    parts: parts,
  );
}

/// 耐心变化（forecastPatience 照抄；去班规项）
double patienceDelta({
  required Set<String> sel,
  required int th,
  required LeaderState state,
  required Scene scene,
  bool accepted = false,
}) {
  final tmp = temptations[scene.temptIdx];
  var pat = -6.0;
  if (sel.contains('enroll')) pat -= 4;
  if (sel.contains('show')) pat += 2;
  if (sel.contains('project')) pat += 3;
  if (sel.contains('rest')) pat += 4;
  if (th > scene.bestLv + 1) pat -= 3;
  final f = forecast(
      sel: sel, th: th, state: state, scene: scene, accepted: accepted);
  if (f.over > 0) pat -= f.over * 2;
  if (state.fatigue > 60) pat -= 3;
  if (accepted && tmp.pat < 0) pat += tmp.pat;
  if (accepted && tmp.pat > 0) pat += tmp.pat;
  return pat;
}

// ---------- 揭示（逐人掷；照 runReveal 的逐人节奏，RNG 播种可复现） ----------

List<bool> revealRolls(String seed, int day, Forecast f) {
  final rnd = mulberry32(hashStr('$seed|reveal|$day'));
  final n = clamp(f.nb, 1, 26).round();
  return [for (var i = 0; i < n; i++) rnd() < f.p];
}

// ---------- 提交后状态推进（finish 照抄，去现金/班规/飞轮） ----------

class WeekResult {
  final LeaderState next;
  final int got, lost, newElders;
  final double rhythmDelta;
  const WeekResult({
    required this.next,
    required this.got,
    required this.lost,
    required this.newElders,
    required this.rhythmDelta,
  });
}

WeekResult applyWeek({
  required LeaderState state,
  required Set<String> sel,
  required int th,
  required Scene scene,
  required List<bool> rolls,
  Elder? lead,
  bool accepted = false,
}) {
  final f = forecast(
      sel: sel, th: th, state: state, scene: scene, lead: lead,
      accepted: accepted);
  final tmp = temptations[scene.temptIdx];
  final mentor = sel.contains('mentor');
  final show = sel.contains('show');
  final screenA = sel.contains('screen');
  final rest = sel.contains('rest');
  final project = sel.contains('project');

  final actual = rolls.where((r) => r).length;

  // 流失：疲劳决定走几个，先走忠诚最低的
  final lossRate =
      state.fatigue > 60 ? 0.22 : (state.fatigue > 40 ? 0.13 : 0.04);
  var lost = (state.roster.length * lossRate).round();
  var roster = [...state.roster];
  for (var li = 0; li < lost && roster.isNotEmpty; li++) {
    var wi = 0;
    for (var lj = 1; lj < roster.length; lj++) {
      if (roster[lj].loyal < roster[wi].loyal) wi = lj;
    }
    roster.removeAt(wi);
  }

  final raw = f.expected * 0.30 +
      (mentor ? 3 : 0) +
      (show ? 5 : 0) -
      lost * 2.5 -
      f.over * 0.9 -
      (state.fatigue > 60 ? 4 : 0);
  final rhythmDelta = raw.roundToDouble();
  var rhythm = clamp(state.rhythm + rhythmDelta, 0, 100);

  // 新骨干：带人时按质量成批长出来
  var newElders = mentor
      ? (f.expected * state.quality * 0.55).round()
      : (f.expected * state.quality * 0.18).round();
  final rnd = mulberry32(hashStr('${scene.bestLv}|new|$th'));
  for (var ni = 0; ni < newElders; ni++) {
    var ne = makeElder(roster.length + ni + 100, rnd);
    if (mentor) {
      ne = ne.copyWith(care: clamp(ne.care + (state.quality * 8).round(), 80, 118).round());
    }
    if (f.over > 0) {
      ne = ne.copyWith(loyal: clamp(ne.loyal - f.over, 35, 96).round());
    }
    roster.add(ne);
  }

  var quality = state.quality;
  if (screenA) quality = clamp(quality + 0.10, 0, 1);
  if (th == scene.bestLv) quality = clamp(quality + 0.05, 0, 1);

  final fatigue = clamp(
      state.fatigue +
          2 +
          (mentor ? 8 : 0) -
          (project ? 12 : 0) -
          (rest ? 10 : 0),
      0,
      100);

  var rep = state.rep +
      (mentor ? 3.5 : 0) +
      (show ? 1.5 : 0) +
      (accepted && tmp.rep != 0 ? tmp.rep : 0) -
      f.over * 0.8 -
      lost * 0.6 -
      (f.p < 0.4 ? 2 : 0);
  rep = clamp(rep, 0, 100);

  var patience = state.patience +
      patienceDelta(
          sel: sel, th: th, state: state, scene: scene, accepted: accepted) +
      (rhythmDelta > 0 ? 2 : 0);
  patience = clamp(patience, 0, 100);

  return WeekResult(
    next: LeaderState(
      rhythm: rhythm,
      quality: quality,
      fatigue: fatigue,
      patience: patience,
      rep: rep,
      roster: roster,
    ),
    got: actual,
    lost: lost,
    newElders: newElders,
    rhythmDelta: rhythmDelta,
  );
}

// ---------- 真反转：学员侧环境 = 班主侧这一周的选择 ----------

class LearnerEnv {
  final bool hasMentor;
  final String mentorName;
  final int over, gate, bestLv;
  final double rhythm, temptRate;
  final String temptTitle;
  const LearnerEnv({
    required this.hasMentor,
    required this.mentorName,
    required this.over,
    required this.gate,
    required this.bestLv,
    required this.rhythm,
    required this.temptRate,
    required this.temptTitle,
  });
}

/// 学员看到的处境，逐项来自班主的选择与这一周的结果——不是换文案。
LearnerEnv envFromLeader({
  required Set<String> sel,
  required int th,
  required Scene scene,
  required Forecast forecastResult,
  required LeaderState nextState,
  Elder? lead,
  bool accepted = false,
}) {
  final tmp = temptations[scene.temptIdx];
  return LearnerEnv(
    hasMentor: sel.contains('mentor') && lead != null,
    mentorName: lead?.name ?? '—',
    over: forecastResult.over,
    gate: th,
    bestLv: scene.bestLv,
    rhythm: nextState.rhythm,
    temptRate: (accepted && tmp.rate != null) ? tmp.rate! : 0,
    temptTitle: accepted ? tmp.title : '',
  );
}

/// 典型班主（未玩过班主周时的缺省环境，取反转关 DEFAULT_OWNER 口径）
LearnerEnv get defaultEnv => const LearnerEnv(
      hasMentor: false,
      mentorName: '—',
      over: 3,
      gate: 3,
      bestLv: 4,
      rhythm: 50,
      temptRate: -0.10,
      temptTitle: '有人劝你把门槛降到最低',
    );

// ---------- 学员侧判定（submitChance 照抄） ----------

class LearnerChoice {
  final Set<String> sel; // seek / submit / pay
  final double confidence, stamina;
  final int tribute;
  const LearnerChoice({
    required this.sel,
    required this.confidence,
    required this.stamina,
    required this.tribute,
  });
}

class LearnerJudgement {
  final double p;
  final bool capped;
  final List<Part> parts;
  const LearnerJudgement({
    required this.p,
    required this.capped,
    required this.parts,
  });
}

LearnerJudgement submitChance({
  required LearnerEnv env,
  required LearnerChoice choice,
}) {
  final seek = choice.sel.contains('seek');
  final hasMentor = env.hasMentor && seek;
  final parts = <Part>[
    Part('班级氛围（${env.rhythm.round()}）', env.rhythm * 0.002, 'env'),
    Part('我的信心（${choice.confidence.round()}）',
        (choice.confidence - 42) * 0.004, 'state'),
    if (hasMentor)
      Part('有人带我 · ${env.mentorName}（决定性）', 0.28, 'seek'),
    Part(
        '门槛设对（Lv${env.gate}）',
        env.gate == env.bestLv
            ? 0.05
            : -0.035 * (env.gate - env.bestLv).abs(),
        'env'),
    Part(
        '我太累了（${choice.stamina.round()}）',
        choice.stamina < 40
            ? -0.12
            : (choice.stamina > 60 ? 0.02 : 0.0),
        'state'),
    Part('身边太挤（过载 ${env.over}）', -clamp(env.over * 0.045, 0, 0.45),
        'env'),
  ];
  if (env.temptRate != 0) {
    parts.add(Part('妥协的代价（${env.temptTitle}）', env.temptRate, 'env'));
  }

  var p = 0.26;
  for (final x in parts) {
    p += x.value;
  }
  p = clamp(p, 0.05, 0.94);

  var capped = false;
  if (!hasMentor && p > 0.48) {
    p = 0.48;
    capped = true;
    parts.add(const Part('⚠ 没人带，我最多只能做到 48%', 0, 'cap'));
  }
  return LearnerJudgement(p: p, capped: capped, parts: parts);
}

/// 学员单次揭示（交成品的成败）
bool revealSubmit(String seed, LearnerJudgement j) =>
    mulberry32(hashStr('$seed|submit'))() < j.p;
