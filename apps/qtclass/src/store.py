# 量潮课堂工作台——河床架构参考实现（快照版）
# 本目录为独立样例：本地 SQLite 存储 + PySide6 界面，无外部服务依赖。

"""学员河床本地存储：SQLite 单文件，零外部依赖。

架构（河床）：学员考核流程是一条连续流程，每个状态迁移都是系统内事件，
不依赖外部服务做缝合。状态枚举即流程状态机的状态集：

    applied → survey_done → invited → task_assigned
            → task_submitted → reviewing → graded → enrolled

终态外分支：dormant（超时未响应，可重新激活）、rejected（未通过，终态）。

身份约定：河床原型以姓名为身份（name UNIQUE）；正式账号体系由组织域承载。
"""

import json
import sqlite3
import threading
from datetime import datetime, timezone
from pathlib import Path

# 数据库与代码同目录存放（data/），保持零配置可跑
DB_PATH = Path(__file__).resolve().parent.parent / 'data' / 'workbench.db'
_lock = threading.Lock()

SCHEMA = """
CREATE TABLE IF NOT EXISTS applications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  school TEXT NOT NULL DEFAULT '',
  course TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'applied',
  survey_json TEXT,
  delivery_json TEXT,
  applied_at TEXT NOT NULL,
  survey_at TEXT
);
"""


def _conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _now() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec='seconds')


def init():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with _lock, _conn() as c:
        c.executescript(SCHEMA)


def create_application(name: str, school: str = '', course: str = '') -> tuple[bool, str]:
    """报名建档（applied）。姓名即身份；重名拦截并返回可读错误。"""
    init()
    try:
        with _lock, _conn() as c:
            c.execute(
                'INSERT INTO applications(name, school, course, status, applied_at)'
                ' VALUES(?,?,?,?,?)',
                (name, school, course, 'applied', _now()))
    except sqlite3.IntegrityError:
        return False, '该姓名已报名——在顶部输入姓名即可查看进度'
    return True, ''


def submit_survey(name: str, answers: dict) -> tuple[bool, str]:
    """问卷提交 = 系统内记录创建（触发器为内部事件，而非外部表单回调）。"""
    return _update(name, status='survey_done', survey_at=_now(),
                   survey_json=json.dumps(answers, ensure_ascii=False))


def grant_invite(name: str) -> tuple[bool, str]:
    """发放入群凭证（系统内动作，取代邮件通知）。凭证直接附带在领任务面板。"""
    return _update(name, status='invited')


def assign_task(name: str) -> tuple[bool, str]:
    """领任务：触发事件 = 学员在工作台内的点击。"""
    return _update(name, status='task_assigned')


def submit_delivery(name: str, delivery: dict) -> tuple[bool, str]:
    """交付物进工作台（系统内上传，取代邮件附件）。"""
    return _update(name, status='task_submitted',
                   delivery_json=json.dumps(delivery, ensure_ascii=False))


def _update(name: str, **fields) -> tuple[bool, str]:
    init()
    sets = ', '.join(f'{k}=?' for k in fields)
    vals = list(fields.values()) + [name]
    with _lock, _conn() as c:
        if c.execute('SELECT 1 FROM applications WHERE name=?', (name,)).fetchone() is None:
            return False, '未找到报名记录，请先完成报名'
        c.execute(f'UPDATE applications SET {sets} WHERE name=?', vals)
    return True, ''



# 评审判定线：达到即达标（实验参数，验收标准见 ../ROADMAP.md）
REVIEW_PASS = 0.70
REQUIRED_SURVEY = ['self_position', 'source', 'research', 'expectation',
                   'leave_responsibility']


def judge(app: dict) -> dict:
    """评审判定：逐项拆开摆出来，看的人能自己加总出结论。

    只用库内真实字段，无随机数——同一份数据任何时候判定一致。
    返回 {'parts': [(标签, 贡献)], 'rate': 0..1, 'passed': bool}
    """
    parts = []

    # 交付要件：没有交付物就没有评审
    has_delivery = bool((app.get('delivery_json') or '').strip())
    parts.append(('交付已提交' if has_delivery else '交付未提交',
                  0.45 if has_delivery else 0.0))

    # 问卷要件：五道必填逐题计
    answers = {}
    raw = app.get('survey_json')
    if raw:
        try:
            answers = json.loads(raw)
        except (TypeError, ValueError):
            answers = {}
    filled = sum(1 for k in REQUIRED_SURVEY if str(answers.get(k, '')).strip())
    parts.append((f'问卷要件 {filled}/{len(REQUIRED_SURVEY)}',
                  round(0.30 * filled / len(REQUIRED_SURVEY), 2)))

    # 报名信息：学校与意向课程
    info = sum(1 for k in ('school', 'course') if str(app.get(k) or '').strip())
    parts.append(('报名信息完整' if info == 2 else f'报名信息 {info}/2',
                  0.10 if info == 2 else 0.05 * info))

    # 问卷时效：报名到问卷 7 天内（旅程规则：超时转休眠）
    timely = 0.0
    if app.get('applied_at') and app.get('survey_at'):
        try:
            applied = datetime.fromisoformat(app['applied_at'])
            surveyed = datetime.fromisoformat(app['survey_at'])
            timely = 0.15 if (surveyed - applied).total_seconds() <= 7 * 86400 else 0.0
        except ValueError:
            timely = 0.0
    parts.append(('问卷 7 天内完成' if timely else '问卷超 7 天', timely))

    rate = round(sum(v for _, v in parts), 2)
    return {'parts': parts, 'rate': rate, 'passed': rate >= REVIEW_PASS}


def get_application(name: str) -> dict | None:
    init()
    with _lock, _conn() as c:
        row = c.execute('SELECT * FROM applications WHERE name=?', (name,)).fetchone()
        return dict(row) if row else None
