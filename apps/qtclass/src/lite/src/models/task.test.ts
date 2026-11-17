import { beforeEach, describe, expect, it } from 'vitest'
import {
  ROLES,
  activeConditions,
  claimTask,
  filterTasks,
  getTasks,
  isClaimed,
  nextSort,
  resetTaskStore,
  sortTasks,
} from './task'

beforeEach(() => {
  resetTaskStore()
})

describe('认领（状态迁移 = 系统内事件）', () => {
  it('一键认领扣一个名额，重复认领被拦截', () => {
    expect(claimTask('xhs-topics')).toBe('ok')
    expect(isClaimed('xhs-topics')).toBe(true)
    const task = getTasks().find((item) => item.id === 'xhs-topics')
    expect(task?.slotsLeft).toBe(4)   // 5 → 4

    expect(claimTask('xhs-topics')).toBe('already')
    expect(getTasks().find((item) => item.id === 'xhs-topics')?.slotsLeft).toBe(4)
  })

  it('名额已满的失败态给原因，不只说操作失败', () => {
    expect(claimTask('copywriting')).toBe('full')
    expect(isClaimed('copywriting')).toBe(false)
  })

  it('大厅与任务库共用同一份载荷', () => {
    claimTask('ai-notes-comp')
    const task = getTasks().find((item) => item.id === 'ai-notes-comp')
    expect(task?.slotsLeft).toBe(1)    // 2 → 1
    expect(isClaimed('ai-notes-comp')).toBe(true)
  })
})

describe('筛选与结果条', () => {
  it('岗位与难度两个维度收敛列表', () => {
    expect(filterTasks({}).length).toBe(getTasks().length)
    expect(filterTasks({ role: '产品' }).every((task) => task.role === '产品')).toBe(true)
    expect(
      filterTasks({ role: '产品', level: '进阶' })
        .every((task) => task.role === '产品' && task.level === '进阶'),
    ).toBe(true)
    expect(filterTasks({ role: '技术', level: '大师' }).length).toBe(0)
  })

  it('周期 / 报酬 / 形式在抽屉里生效', () => {
    expect(filterTasks({ period: '7' }).every((task) => task.days <= 7)).toBe(true)
    expect(filterTasks({ rewardAt: 1000 }).every((task) => task.reward >= 1000)).toBe(true)
    expect(filterTasks({ mode: '线下' }).length).toBe(0)
  })

  it('关键词命中标题、企业与标签', () => {
    expect(filterTasks({ keyword: '访谈' }).map((task) => task.id)).toEqual(['user-interview'])
    expect(filterTasks({ keyword: '星野' }).length).toBe(
      getTasks().filter((task) => task.corp === '星野科技').length,
    )
    expect(filterTasks({ keyword: '运营' }).every((task) => task.role === '运营')).toBe(true)
  })

  it('已选条件数：默认值不计，每多选一项 +1', () => {
    expect(activeConditions({})).toBe(0)
    expect(activeConditions({ role: '产品', level: '进阶' })).toBe(2)
    expect(activeConditions({ role: '全部', keyword: ' ' })).toBe(0)
    expect(activeConditions({ keyword: '访谈', role: '产品', period: '7', rewardAt: 500 })).toBe(4)
  })

  it('岗位选项与模型枚举同源', () => {
    expect(ROLES).toEqual(['技术', '运营', '产品', '设计'])
  })
})

describe('排序', () => {
  it('报酬降序、截止临近优先', () => {
    const rewards = sortTasks(getTasks(), 'reward').map((task) => task.reward)
    expect([...rewards].sort((a, b) => b - a)).toEqual(rewards)

    const deadlines = sortTasks(getTasks(), 'deadline').map((task) => task.deadline)
    expect([...deadlines].sort((a, b) => a.localeCompare(b))).toEqual(deadlines)
  })

  it('排序按钮循环：最新发布 → 报酬最高 → 临近截止', () => {
    expect(nextSort('latest')).toBe('reward')
    expect(nextSort('reward')).toBe('deadline')
    expect(nextSort('deadline')).toBe('latest')
  })
})
