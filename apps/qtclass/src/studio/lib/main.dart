import 'package:flutter/material.dart';

import 'judge.dart';

const primary = Color(0xFF2F54EB);

void main() => runApp(const LabApp());

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮课堂工作台 · 判定实验',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
      ),
      home: const WorkbenchPage(),
    );
  }
}

/// 演示记录：一条走到评审（带判定卡），一条停在任务进行中（带动作，
/// 用来验班主视角的只读门）。
class DemoRecord {
  final String name;
  final String course;
  final String stage;
  final String learnerDesc;
  final String ownerDesc;
  final JudgeResult? judge;
  final String? action;

  const DemoRecord({
    required this.name,
    required this.course,
    required this.stage,
    required this.learnerDesc,
    required this.ownerDesc,
    this.judge,
    this.action,
  });
}

final demoRecords = [
  DemoRecord(
    name: '判定面板学员',
    course: '知识工作（入门）',
    stage: '评审中',
    learnerDesc: '交付物进入双人评审（代表初审 + 负责人终审），约 7 天出结论。',
    ownerDesc: '交付已进评审；判定明细与他看到的完全一致，结论出来即可入册。',
    judge: judge(
      hasDelivery: true,
      answers: const {
        'self_position': '愿意踏实地学',
        'source': 'GitHub',
        'research': '读过开源章程与课程介绍',
        'expectation': '建立数据工程完整认知',
        'leave_responsibility': '交接进行中的任务',
      },
      schoolFilled: true,
      courseFilled: true,
      surveyDelay: const Duration(days: 2),
    ),
  ),
  const DemoRecord(
    name: '任务进行中学员',
    course: '氛围编程（入门）',
    stage: '任务进行中',
    learnerDesc: '按任务 deadline 完成后，在工作台直接提交交付物，交付即进入评审队列。',
    ownerDesc: '任务进行中；卡不卡、要不要推一把，看交付。',
    action: '提交交付物',
  ),
];

class WorkbenchPage extends StatefulWidget {
  const WorkbenchPage({super.key});

  @override
  State<WorkbenchPage> createState() => _WorkbenchPageState();
}

class _WorkbenchPageState extends State<WorkbenchPage> {
  int _recordIdx = 0;
  bool _ownerView = false;
  bool _detailOpen = false;

  DemoRecord get _record => demoRecords[_recordIdx];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = _record;

    return Scaffold(
      appBar: AppBar(
        title: const Text('量潮课堂工作台 · 判定实验'),
        actions: [
          const Text('班主视角'),
          Switch(
            value: _ownerView,
            onChanged: (_) => setState(() {
              _ownerView = !_ownerView;
              _detailOpen = false;
            }),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 演示记录选择
          SegmentedButton<int>(
            segments: [
              for (var i = 0; i < demoRecords.length; i++)
                ButtonSegment(value: i, label: Text(demoRecords[i].name)),
            ],
            selected: {_recordIdx},
            onSelectionChanged: (s) => setState(() {
              _recordIdx = s.first;
              _detailOpen = false;
            }),
          ),
          const SizedBox(height: 16),

          // 阶段卡
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: Text(record.stage)),
                      const SizedBox(width: 10),
                      Text(record.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(record.course, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ownerView
                        ? '班主视角 · 只读 · 观察对象：${record.name}'
                        : '报名学员：${record.name}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ownerView ? record.ownerDesc : record.learnerDesc,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  // 判定卡（实验一）：两个大数字 + 默认收起的逐项明细
                  if (record.judge != null) ...[
                    Row(
                      children: [
                        _BigNumber(
                          value: '${(record.judge!.rate * 100).round()}%',
                          caption: '判定率',
                          color: record.judge!.passed
                              ? const Color(0xFF12A66A)
                              : const Color(0xFFF5222D),
                        ),
                        const SizedBox(width: 28),
                        _BigNumber(
                          value: '${(reviewPass * 100).round()}%',
                          caption: '达标线',
                          color: theme.colorScheme.onSurface,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.judge!.passed
                          ? '✓ 判定达标，待双人评审确认'
                          : '✗ 距达标还差 '
                              '${((reviewPass - record.judge!.rate) * 100).round()} 个百分点',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _detailOpen = !_detailOpen),
                      child: Text(_detailOpen ? '收起明细 ▴' : '逐项明细 ▸'),
                    ),
                    if (_detailOpen) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (label, value) in record.judge!.parts)
                              Text(
                                '$label  ${value >= 0 ? '+' : ''}'
                                '${value.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            const SizedBox(height: 6),
                            Text(
                              '—— 逐项加总 '
                              '${record.judge!.rate.toStringAsFixed(2)}'
                              '（达标线 ${reviewPass.toStringAsFixed(2)}）；'
                              '只用给定字段，同一份数据判定一致',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // 动作（实验二的只读门）
                  if (record.action != null) ...[
                    const SizedBox(height: 12),
                    if (_ownerView)
                      Text('只读视角：动作由学员本人完成。',
                          style: theme.textTheme.bodySmall)
                    else
                      FilledButton(
                        onPressed: () {},
                        child: Text(record.action!),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String value;
  final String caption;
  final Color color;

  const _BigNumber({
    required this.value,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700,
                color: color)),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
