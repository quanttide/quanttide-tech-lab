# 量潮课堂 Lite（实验室快照）

按 [dev-guide/lite.html](../../docs/dev-guide/lite.html)《页面说明与 UX 优化方案 v0.3》实现的 C 端任务端：任务大厅 / 任务库 / 个人 / 指南四页，底部三页签（任务 / 指南 / 个人）。

技术形态与正式 lite 不同：正式 lite 是 React + Vite 的 Web 端（`quanttide/apps/qtclass/src/lite`），本仓快照是 **Taro 4 + React + TypeScript 微信小程序**——Taro 外壳与工程配置对齐 `quanttide/apps/qtcloud/src/lite`，应用结构（models / pages / components 分层、契约静态先行）对齐正式 lite。同属三级火箭中的 lite 层（site / lite / studio），面向学员「在做，不在看」。

## 开发

```bash
npm install --legacy-peer-deps   # vitest 的 vite 与 Taro 的 peer 约束冲突，按 Taro 生态惯例跳过
npm run dev:weapp   # watch 构建，微信开发者工具导入 dist/
npm run build:weapp # 一次性构建
npm run dev:h5      # 浏览器本地预览（h5，Taro 开发服务器）
npm run tsc         # 类型检查
npm test            # vitest：认领状态机 / 筛选 / 排序
```

无微信开发者工具时用 h5 端本地跑：`npm run build:h5` 后用任意静态服务器托管 `dist/`（默认路由为 hash，入口 `/#/`）。`dist/` 为两端共用，构建哪端就覆盖哪端。h5 端 Taro 路由器未实现 `tabBar.custom`（源码里是 TODO），页签栏由 `app.tsx` 手动补挂；weapp 端仍由框架在页签页挂载 `custom-tab-bar/`，两端共用同一组件与 `models/tab` 的选中态/显隐开关。

`project.config.json` 用游客 appid（`touristappid`），开发者工具直接打开即可预览，无需注册 appid。

## 上线

实验室原型站（GitHub Pages）：**https://quanttide.github.io/quanttide-tech-lab/** ——可交互实现位于站内 `qtclass/src/lite/dist/`，与原型稿（`qtclass/docs/dev-guide/lite.html`）一起由入口页导航。push `apps/**` 时 CI 自动 `build:h5` 并部署；`h5.publicPath: './'` 保证资源在子路径下可用。

## 结构

```
config/                 # Taro 构建配置（designWidth 375：样式 px 即原型 px）
src/
├── app.config.ts       # 四页路由 + 自定义顶栏 + 自定义页签栏
├── models/task.ts      # 任务契约（Task 形状）+ 静态载荷 + 认领/筛选/排序（单一事实源）
├── models/tab.ts       # 页签路由表与选中态（自定义 tabBar 没有原生选中态可用）
├── pages/
│   ├── hall/           # P1 任务大厅：搜索 + AI 简报 + 岗位芯片 + 推荐任务
│   ├── library/        # P2 任务库：两排筛选 + 更多抽屉 + 结果条（压入页）
│   ├── mine/           # P3 个人：名片 + 接单/发布 + 能力标签 + 设置列表
│   └── guide/          # P4 指南：新手三步 + 内容列表 + 版本条
├── components/         # AppBar（自定义顶栏）/ TaskCard（大厅与任务库共用）/ icons
└── custom-tab-bar/     # 自定义页签栏：图标 + 文字 + 颜色 + 字重三重选中反馈
```

## 数据面

契约静态先行：页面只认 `models/task.ts` 的 `Task` 形状，载荷是原型样例数据（含 1 条满额任务，用于演示「名额已满」失败态）；provider 接通后换数据源，页面不动。

认领是模块级内存状态（快照不落库）：大厅与任务库共用同一份名额，`claimTask` 返回 `ok / already / full`——失败态给原因，不只说「操作失败」（原型「三类必须设计的状态」）。

个人页数字（累计接单 / 完成率 / 评分等）为原型静态载荷；接通登录与任务记录后由真实数据替换。

## 原型对照（实现相对原型的两处偏差）

- **任务库的返回入口**：原型任务库带底部页签（mockup 惯例），小程序压入页按微信惯例隐藏页签，顶栏左侧补返回按钮（无历史可退时回任务大厅）。
- **更多筛选**：原型把三组条件画在「更多」行内，但标注 4 说它们收进抽屉——按标注实现：抽屉承载周期 / 报酬 / 形式，已选条件数以角标显示在按钮上，行内只回显已选项（点一下即撤掉）。
