// 底部页签的路由表、选中态与显隐：页签栏组件订阅它，各页 onShow 时按当前路由回写——
// 自定义 tabBar 没有原生选中态可用，选中值必须有单一来源。
// 显隐同理：压入页（任务库）不显示页签，h5 端页签栏挂在 App 上，靠这个开关收敛。

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
let visible = true
const listeners = new Set<() => void>()

function notify(): void {
  listeners.forEach((listener) => listener())
}

export function getSelected(): number {
  return selected
}

export function getVisible(): boolean {
  return visible
}

export function setSelected(index: number): void {
  if (index < 0 || index >= TABS.length || index === selected) return
  selected = index
  notify()
}

export function setVisible(value: boolean): void {
  if (value === visible) return
  visible = value
  notify()
}

export function subscribeTab(listener: () => void): () => void {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}

// 非页签的压入页：路由命中时隐藏页签栏（weapp 端框架本就不挂载，这里主要管 h5）
const PUSH_PAGES = ['/pages/library/index']

// 按当前页面路由回写选中态与显隐：页签页高亮对应项并显示，压入页隐藏。
// h5 端的 route 可能带前导斜杠或为入口 '/', 归一化后再比对；路由未知时不动状态。
export function syncSelectedFromRoute(): void {
  const pages = Taro.getCurrentPages()
  const last = pages[pages.length - 1]
  const route = (last?.route ?? '').replace(/^\//, '').split('?')[0]
  if (!route || route === 'index.html') return  // 路由未知（启动早期）：不动显隐与选中
  const index = TABS.findIndex((tab) => tab.pagePath.slice(1) === route)
  if (index >= 0) {
    setSelected(index)
    setVisible(true)
  } else if (PUSH_PAGES.includes(`/${route}`)) {
    setVisible(false)
  }
}
