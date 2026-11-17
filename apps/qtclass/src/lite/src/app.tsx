import { PropsWithChildren } from 'react'
import { useLaunch } from '@tarojs/taro'
import CustomTabBar from './custom-tab-bar'

import './app.scss'

function App({ children }: PropsWithChildren<any>) {
  useLaunch(() => {
    console.log('qtclass lite launched.')
  })

  // children 是将要渲染的页面。
  // 页签栏：weapp 端由框架在页签页挂载 custom-tab-bar；h5 端 Taro 路由器对
  // tabBar.custom 直接跳过（未实现），这里手动补挂——显隐由 models/tab 的开关收敛。
  return (
    <>
      {children}
      {process.env.TARO_ENV === 'h5' && <CustomTabBar />}
    </>
  )
}

export default App
