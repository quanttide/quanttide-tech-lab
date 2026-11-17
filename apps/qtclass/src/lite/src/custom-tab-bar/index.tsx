import { useEffect, useState } from 'react'
import { Text, View } from '@tarojs/components'
import Taro from '@tarojs/taro'
import { ICONS } from '../components/icons'
import { TABS, getSelected, getVisible, subscribeTab, syncSelectedFromRoute } from '../models/tab'

const TAB_ICONS = {
  tasks: ICONS.tabTasks,
  guide: ICONS.tabGuide,
  mine: ICONS.tabMine,
}

// 自定义页签栏（tabBar.custom）：图标 + 文字 + 颜色 + 字重三重选中反馈，四页共用——
// 选中态与显隐的单一来源是 models/tab：各页 onShow 回写，本组件订阅刷新。
// weapp 端由框架在页签页挂载；h5 端框架不支持 custom（Taro 路由器直接跳过），由 App 挂载。
function CustomTabBar() {
  const [, setTick] = useState(0)

  useEffect(() => {
    syncSelectedFromRoute()
    const unsubscribe = subscribeTab(() => setTick((value) => value + 1))
    return () => {
      unsubscribe()
    }
  }, [])

  if (!getVisible()) return null

  const selected = getSelected()

  const onSwitch = (index: number) => {
    if (index === selected) return
    Taro.switchTab({ url: TABS[index].pagePath })
  }

  return (
    <View className='tabBar'>
      {TABS.map((tab, index) => {
        const on = index === selected
        return (
          <View
            key={tab.pagePath}
            className={`tabItem${on ? ' on' : ''}`}
            onClick={() => onSwitch(index)}
          >
            <View className='tabIcon' style={{ backgroundImage: TAB_ICONS[tab.icon](on) }} />
            <Text className='tabLabel'>{tab.label}</Text>
          </View>
        )
      })}
    </View>
  )
}

export default CustomTabBar
