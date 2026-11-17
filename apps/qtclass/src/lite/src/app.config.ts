// 页签三页：任务大厅 / 指南 / 个人；任务库为压入页（大厅「全部」进入，返回可退）
// 顶栏走自定义（navigationStyle: custom）——原型的标题 + 右侧动作图标由 AppBar 组件承载
export default defineAppConfig({
  pages: [
    'pages/hall/index',
    'pages/guide/index',
    'pages/mine/index',
    'pages/library/index',
  ],
  window: {
    navigationStyle: 'custom',
    backgroundTextStyle: 'light',
    backgroundColor: '#F4F6FA',
    navigationBarTitleText: '量潮课堂',
    navigationBarTextStyle: 'black',
  },
  tabBar: {
    // 自定义页签栏：图标 + 文字 + 选中态（颜色 + 字重），四页共用同一组件
    custom: true,
    color: '#9AA9BA',
    selectedColor: '#0F5BFF',
    backgroundColor: '#ffffff',
    list: [
      { pagePath: 'pages/hall/index', text: '任务' },
      { pagePath: 'pages/guide/index', text: '指南' },
      { pagePath: 'pages/mine/index', text: '个人' },
    ],
  },
})
