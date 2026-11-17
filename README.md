# 量潮科技实验室

公司级实验空间：正式流程之外「先试一试」的地方。实验验证有效后，把方法与经验提取到对应档案、产品与流程。

## 结构

| 目录 | 说明 |
|------|------|
| `docs/` | 实验文档 |
| `apps/` | 应用实验（qtclass 等）；原型站入口 `apps/index.html` |

## 原型站

GitHub Pages：**https://quanttide.github.io/quanttide-tech-lab/**

入口为 `apps/index.html`，聚合各应用的界面原型与可交互实现。push `apps/**` 时由 `.github/workflows/deploy-pages.yml` 自动构建（含 lite h5）并部署，站点根即 `apps/` 内容。

## 工作纪律

见 [AGENTS.md](./AGENTS.md)：人类优先于 AI，结构性变更前先确认。
