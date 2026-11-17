import { useEffect, useState } from 'react'
import { Text, View } from '@tarojs/components'
import Taro from '@tarojs/taro'
import { ICONS } from '../components/icons'
import { TABS, getSelected, subscribeSelected, syncSelectedFromRoute } from '../models/tab'

const TAB_ICONS = {
  tasks: ICONS.tabTasks,
  guide: ICONS.tabGuide,
  mine: ICONS.tabMine,
}

// 自定义页签栏（tabBar.custom）：图标 + 文字 + 颜色 + 字重三重选中反馈，四页共用——
// 选中态单一来源是 models/tab：各页 onShow 回写，本组件订阅刷新。
function CustomTabBar() {
  const [selected, setSelected] = useState(getSelected())

  useEffect(() => {
    syncSelectedFromRoute()
    const unsubscribe = subscribeSelected(setSelected)
    return () => {
      unsubscribe()
    }
  }, [])

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
