import { PropsWithChildren } from 'react'
import { useLaunch } from '@tarojs/taro'

import './app.scss'

function App({ children }: PropsWithChildren<any>) {
  useLaunch(() => {
    console.log('qtclass lite launched.')
  })

  // children 是将要渲染的页面
  return children
}

export default App
