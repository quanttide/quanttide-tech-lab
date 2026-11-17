import type { ReactNode } from 'react'
import { Text, View } from '@tarojs/components'
import Taro from '@tarojs/taro'
import { ICONS } from './icons'

interface Props {
  title: string
  onBack?: () => void      // 压入页给返回；页签根页不给
  action?: ReactNode       // 右侧动作（原型：通知 / 搜索 / 设置 / 反馈）
}

// 自定义顶栏（navigationStyle: custom）：状态栏高度取系统值，内容区用两段垫片对齐——
// 顶栏固定在顶上，页面滚动时不会钻到状态栏底下。
function AppBar({ title, onBack, action }: Props) {
  const statusBarHeight = Taro.getWindowInfo().statusBarHeight ?? 20
  return (
    <>
      <View className='appBar' style={{ paddingTop: `${statusBarHeight}px` }}>
        <View className='appBarRow'>
          {onBack && (
            <View
              className='appBarBtn'
              style={{ backgroundImage: ICONS.back }}
              onClick={onBack}
            />
          )}
          <Text className='appBarTitle'>{title}</Text>
          <View className='appBarActions'>{action}</View>
        </View>
      </View>
      <View style={{ height: `${statusBarHeight}px` }} />
      <View className='appBarGap' />
    </>
  )
}

export default AppBar
