// 底部页签的路由表与选中态：页签栏组件订阅它，各页 onShow 时按当前路由回写——
// 自定义 tabBar 没有原生选中态可用，选中值必须有单一来源。

import Taro from '@tarojs/taro'

export interface TabItem {
  pagePath: string
  label: string
  icon: 'tasks' | 'guide' | 'mine'
}

// 顺序即导航顺序：任务 / 指南 / 个人（与原型底部导航一致）
export const TABS: TabItem[] = [
  { pagePath: '/pages/hall/index', label: '任务', icon: 'tasks' },
  { pagePath: '/pages/guide/index', label: '指南', icon: 'guide' },
  { pagePath: '/pages/mine/index', label: '个人', icon: 'mine' },
]

let selected = 0
const listeners = new Set<(index: number) => void>()

export function getSelected(): number {
  return selected
}

export function setSelected(index: number): void {
  if (index < 0 || index >= TABS.length || index === selected) return
  selected = index
  listeners.forEach((listener) => listener(index))
}

export function subscribeSelected(listener: (index: number) => void): () => void {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

// 按当前页面路由回写选中态（各页 useDidShow 调用；压入页不调用，页签栏也不渲染）
export function syncSelectedFromRoute(): void {
  const pages = Taro.getCurrentPages()
  const route = pages[pages.length - 1]?.route ?? ''
  const index = TABS.findIndex((tab) => tab.pagePath.slice(1) === route)
  if (index >= 0) setSelected(index)
}
