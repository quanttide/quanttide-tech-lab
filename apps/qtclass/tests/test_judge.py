# 判定明细实验：确定性与可复算（逻辑测试不触 GUI；面板冒烟在最后）

import json

import store

ANSWERS = {
    'self_position': '我更多是抱着学习的想法来的，渴望成长，愿意踏实地学',
    'source': 'GitHub',
    'research': '读过开源章程与课程介绍',
    'expectation': '1-2 个月内建立数据工程完整认知',
    'leave_responsibility': '交接进行中的任务，说明进度与原因',
}


def _app(**over):
    base = dict(
        name='判定学员', school='测试大学', course='知识工作（入门）',
        status='task_submitted',
        survey_json=json.dumps(ANSWERS, ensure_ascii=False),
        delivery_json=json.dumps({'filename': 'report.md'}, ensure_ascii=False),
        applied_at='2026-11-01T10:00:00+08:00',
        survey_at='2026-11-03T10:00:00+08:00',
    )
    base.update(over)
    return base


class TestJudge:
    def test_full_submission_passes(self):
        j = store.judge(_app())
        # 可复算：明细加总 == 判定率
        assert abs(sum(v for _, v in j['parts']) - j['rate']) < 1e-9
        assert j['rate'] == 1.0
        assert j['passed'] is True

    def test_missing_delivery_fails(self):
        j = store.judge(_app(delivery_json=''))
        assert j['passed'] is False
        assert j['rate'] <= 0.55

    def test_partial_survey_exact_penalty(self):
        answers = dict(ANSWERS)
        del answers['research']
        j = store.judge(_app(survey_json=json.dumps(answers, ensure_ascii=False)))
        assert abs(j['rate'] - (1.0 - 0.30 / 5)) < 1e-9
        assert j['passed'] is True  # 0.94 ≥ 0.70

    def test_late_survey_loses_timeliness(self):
        j = store.judge(_app(survey_at='2026-11-15T10:00:00+08:00'))
        assert abs(j['rate'] - 0.85) < 1e-9

    def test_deterministic(self):
        assert store.judge(_app()) == store.judge(_app())


class TestReviewPanel:
    """面板冒烟：判定卡出现、明细可展开、班主视角换主语不换数字。"""

    NAME = '判定面板学员'

    def _journey_to_review(self, tmp_store):
        tmp_store.create_application(self.NAME, school='测试大学',
                                     course='知识工作（入门）')
        tmp_store.submit_survey(self.NAME, ANSWERS)
        tmp_store.grant_invite(self.NAME)
        tmp_store.assign_task(self.NAME)
        tmp_store.submit_delivery(self.NAME, {'filename': 'x.md'})

    def _labels(self, window):
        out = []

        def walk(layout):
            for i in range(layout.count()):
                item = layout.itemAt(i)
                w = item.widget()
                if w is not None:
                    out.append(w)
                elif item.layout() is not None:
                    walk(item.layout())

        walk(window.detail)
        return out

    def test_verdict_card_and_toggle(self, window, tmp_store):
        self._journey_to_review(tmp_store)
        window.query_name.setText(self.NAME)
        window._on_query()
        texts = [w.text() for w in self._labels(window)
                 if hasattr(w, 'text')]
        assert any(t.endswith('%') for t in texts), '判定率大数字应出现'
        assert '判定率' in texts and '达标线' in texts
        assert any('判定达标' in t for t in texts)

        # 明细默认收起，点开可见
        btn = next(w for w in self._labels(window)
                   if hasattr(w, 'text') and w.text().startswith('逐项明细'))
        det = next(w for w in self._labels(window)
                   if hasattr(w, 'text') and '逐项加总' in w.text())
        assert det.isHidden()
        btn.click()
        assert not det.isHidden()
        # 可复算：明细里的贡献加总 == 判定率
        total = sum(float(line.rsplit(' ', 1)[1])
                    for line in det.text().splitlines()
                    if line and not line.startswith('——'))
        assert abs(total - store.judge(
            store.get_application(self.NAME))['rate']) < 1e-9

    def test_owner_view_same_numbers_readonly(self, window, tmp_store):
        # 先走到「任务进行中」（有动作的阶段）验证只读门
        tmp_store.create_application(self.NAME, school='测试大学',
                                     course='知识工作（入门）')
        tmp_store.submit_survey(self.NAME, ANSWERS)
        tmp_store.grant_invite(self.NAME)
        tmp_store.assign_task(self.NAME)
        window.query_name.setText(self.NAME)
        window._on_query()
        assert any('提交交付物' in t for t in
                   [w.text() for w in self._labels(window) if hasattr(w, 'text')])

        window.owner_btn.setChecked(True)
        owner_texts = [w.text() for w in self._labels(window)
                       if hasattr(w, 'text')]
        # 换主语：观察文案出现，动作隐去
        assert any('班主视角' in t for t in owner_texts)
        assert not any('提交交付物' in t for t in owner_texts)
        assert any('只读视角' in t for t in owner_texts)

        # 关掉开关回到学员视角，动作回来
        window.owner_btn.setChecked(False)
        back = [w.text() for w in self._labels(window)
                if hasattr(w, 'text')]
        assert any('提交交付物' in t for t in back)
        assert not any('班主视角' in t for t in back)

        # 交付后：判定卡在两个视角下数字一致
        tmp_store.submit_delivery(self.NAME, {'filename': 'x.md'})
        window._on_query()
        learner = [w.text() for w in self._labels(window)
                   if hasattr(w, 'text')]
        assert '判定率' in learner and any(t.endswith('%') for t in learner)

        window.owner_btn.setChecked(True)
        owner = [w.text() for w in self._labels(window)
                 if hasattr(w, 'text')]
        assert '判定率' in owner
        assert [t for t in owner if t.endswith('%')] == \
               [t for t in learner if t.endswith('%')]
