// 任务契约与静态载荷（照正式 lite 的惯例：契约静态先行，页面只认本形状）。
// 认领状态是模块级快照——大厅与任务库共用同一份数据，卡片复用同一套组件。

export type Role = '技术' | '运营' | '产品' | '设计'
export type Level = '初级' | '进阶' | '大师'

export interface Task {
  id: string
  corp: string        // 发布方
  logo: 'b' | 'g' | 'o'  // 企业 logo 配色档（蓝 / 绿 / 橙）
  reward: number      // 报酬（元）
  title: string
  role: Role          // 岗位：决定做什么
  level: Level        // 难度：决定能不能做
  mode: '线上' | '线下'
  days: number        // 周期（天）
  slotsTotal: number  // 名额总数
  slotsLeft: number   // 剩余名额
  deadline: string    // 截止（MM-DD）
}

// 静态载荷（原型样例数据）：provider 接通后换数据源，页面不动
const SEED: Task[] = [
  { id: 'ai-notes-comp', corp: '星野科技', logo: 'b', reward: 800,
    title: 'AI 笔记类工具竞品分析报告（含功能对比矩阵）',
    role: '产品', level: '进阶', mode: '线上', days: 7,
    slotsTotal: 5, slotsLeft: 2, deadline: '11-24' },
  { id: 'xhs-topics', corp: '杭州潮玩文化', logo: 'g', reward: 300,
    title: '小红书内容选题库搭建：30 条可执行选题',
    role: '运营', level: '初级', mode: '线上', days: 3,
    slotsTotal: 10, slotsLeft: 5, deadline: '11-21' },
  { id: 'user-interview', corp: '云图数据', logo: 'o', reward: 1200,
    title: '用户访谈提纲设计 + 8 场访谈执行',
    role: '产品', level: '进阶', mode: '线上', days: 14,
    slotsTotal: 3, slotsLeft: 1, deadline: '12-01' },
  { id: 'member-system', corp: '杭州潮玩文化', logo: 'g', reward: 600,
    title: '会员体系改版方案：从积分到等级',
    role: '产品', level: '进阶', mode: '线上', days: 10,
    slotsTotal: 4, slotsLeft: 3, deadline: '11-28' },
  { id: 'activity-page', corp: '星野科技', logo: 'b', reward: 500,
    title: '双 12 活动页 H5 制作（2 个页面，含埋点说明）',
    role: '技术', level: '初级', mode: '线上', days: 4,
    slotsTotal: 8, slotsLeft: 6, deadline: '11-22' },
  { id: 'perf-tuning', corp: '星野科技', logo: 'b', reward: 1500,
    title: '课程官网移动端性能优化（首屏 < 2s）',
    role: '技术', level: '进阶', mode: '线上', days: 14,
    slotsTotal: 4, slotsLeft: 2, deadline: '12-05' },
  { id: 'dashboard-spec', corp: '云图数据', logo: 'o', reward: 450,
    title: '数据看板视觉规范整理（组件级标注）',
    role: '设计', level: '初级', mode: '线上', days: 5,
    slotsTotal: 6, slotsLeft: 4, deadline: '11-26' },
  { id: 'copywriting', corp: '杭州潮玩文化', logo: 'g', reward: 350,
    title: '品牌文案 8 条（活动主题 + 社媒口径）',
    role: '运营', level: '初级', mode: '线上', days: 3,
    slotsTotal: 4, slotsLeft: 0, deadline: '11-20' },
]

// ---- 认领状态（大厅与任务库共享；测试用 resetTaskStore 复位） ----

let tasks: Task[] = SEED.map((task) => ({ ...task }))
const claimed = new Set<string>()

export type ClaimResult = 'ok' | 'already' | 'full'

export function getTasks(): Task[] {
  return tasks
}

export function isClaimed(id: string): boolean {
  return claimed.has(id)
}

export function claimedCount(): number {
  return claimed.size
}

// 一键认领：抢一个名额；已认领拦截重复，名额耗尽按失败态返回（不只说「操作失败」）
export function claimTask(id: string): ClaimResult {
  if (claimed.has(id)) return 'already'
  const task = tasks.find((item) => item.id === id)
  if (!task || task.slotsLeft <= 0) return 'full'
  task.slotsLeft -= 1
  claimed.add(id)
  return 'ok'
}

export function resetTaskStore(): void {
  tasks = SEED.map((task) => ({ ...task }))
  claimed.clear()
}

// ---- 筛选与排序（大厅与任务库共用） ----

export const ROLES: Role[] = ['技术', '运营', '产品', '设计']
export const LEVELS: Level[] = ['初级', '进阶', '大师']

export interface Query {
  keyword?: string
  role?: Role | '全部'
  level?: Level | '全部'
  period?: string | null    // 周期抽屉：7 天内 / 14 天内
  rewardAt?: number | null  // 报酬抽屉：500 / 1000
  mode?: '线上' | '线下' | null
}

function matchKeyword(task: Task, keyword?: string): boolean {
  const kw = keyword?.trim()
  if (!kw) return true
  return task.title.includes(kw) || task.corp.includes(kw) ||
    task.role.includes(kw) || task.level.includes(kw)
}

export function filterTasks(query: Query): Task[] {
  return tasks.filter((task) =>
    matchKeyword(task, query.keyword) &&
    (!query.role || query.role === '全部' || task.role === query.role) &&
    (!query.level || query.level === '全部' || task.level === query.level) &&
    (!query.period || task.days <= Number(query.period)) &&
    (!query.rewardAt || task.reward >= query.rewardAt) &&
    (!query.mode || task.mode === query.mode))
}

// 已选条件数：结果条的「已选 N 个条件」（默认值不计）
export function activeConditions(query: Query): number {
  let n = 0
  if (query.keyword?.trim()) n += 1
  if (query.role && query.role !== '全部') n += 1
  if (query.level && query.level !== '全部') n += 1
  if (query.period) n += 1
  if (query.rewardAt) n += 1
  if (query.mode) n += 1
  return n
}

export type SortKey = 'latest' | 'reward' | 'deadline'

export const SORT_LABELS: Record<SortKey, string> = {
  latest: '最新发布',
  reward: '报酬最高',
  deadline: '临近截止',
}

export const SORT_ORDER: SortKey[] = ['latest', 'reward', 'deadline']

export function sortTasks(list: Task[], sort: SortKey): Task[] {
  const copy = [...list]
  if (sort === 'reward') return copy.sort((a, b) => b.reward - a.reward)
  if (sort === 'deadline') return copy.sort((a, b) => a.deadline.localeCompare(b.deadline))
  return copy  // 最新发布 = 载荷顺序
}

export function nextSort(sort: SortKey): SortKey {
  return SORT_ORDER[(SORT_ORDER.indexOf(sort) + 1) % SORT_ORDER.length]
}
