// 图标：data URI SVG——小程序不支持内联 <svg>，把原型里的线性图标烘成背景图。
// 颜色直接烘进 SVG（背景图不继承 currentColor），需要双色的（页签图标）各出一档。

function svgIcon(
  body: string,
  color: string,
  opts: { fill?: boolean; strokeWidth?: number } = {},
): string {
  const fill = opts.fill ?? false
  const strokeWidth = opts.strokeWidth ?? 1.9
  const svg =
    `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='${fill ? color : 'none'}'` +
    ` stroke='${fill ? 'none' : color}' stroke-width='${strokeWidth}'` +
    ` stroke-linecap='round' stroke-linejoin='round'>${body}</svg>`
  return `url("data:image/svg+xml,${encodeURIComponent(svg)}")`
}

const GRAY = '#9AA9BA'   // 页签未选中
const BRAND = '#0F5BFF'  // 页签选中 / 主行动
const ICON = '#40536B'   // 顶栏动作
const MUTED = '#8A9BB0'  // 搜索占位
const CHEV = '#C2CEDC'   // 行尾箭头
const SOFT = '#5B6D82'   // 列表小图标

export const ICONS = {
  // 底部页签（选中 / 未选中两档）
  tabTasks: (on: boolean) => svgIcon(
    `<rect x='4' y='3' width='16' height='18' rx='2.5'/><path d='M8.5 8.5h7M8.5 12.5h7M8.5 16.5h4'/>`,
    on ? BRAND : GRAY, { strokeWidth: 1.9 }),
  tabGuide: (on: boolean) => svgIcon(
    `<path d='M4 5.5A1.5 1.5 0 0 1 5.5 4H10v15H5.5A1.5 1.5 0 0 0 4 20.5z'/>` +
    `<path d='M20 5.5A1.5 1.5 0 0 0 18.5 4H14v15h4.5a1.5 1.5 0 0 1 1.5 1.5z'/>`,
    on ? BRAND : GRAY, { strokeWidth: 1.9 }),
  tabMine: (on: boolean) => svgIcon(
    `<circle cx='12' cy='8' r='3.6'/><path d='M4.5 20a7.5 7.5 0 0 1 15 0'/>`,
    on ? BRAND : GRAY, { strokeWidth: 1.9 }),

  // 顶栏动作
  bell: svgIcon(
    `<path d='M18 8a6 6 0 1 0-12 0c0 7-3 8-3 8h18s-3-1-3-8'/>` +
    `<path d='M13.7 21a2 2 0 0 1-3.4 0'/>`, ICON, { strokeWidth: 1.7 }),
  search: svgIcon(`<circle cx='11' cy='11' r='7'/><path d='m20 20-3.5-3.5'/>`, ICON),
  searchMuted: svgIcon(`<circle cx='11' cy='11' r='7'/><path d='m20 20-3.5-3.5'/>`, MUTED,
    { strokeWidth: 2 }),
  back: svgIcon(`<path d='M15 5l-7 7 7 7'/>`, ICON, { strokeWidth: 1.8 }),
  gear: svgIcon(
    `<circle cx='12' cy='12' r='3.2'/>` +
    `<path d='M12 3v2.5M12 18.5V21M3 12h2.5M18.5 12H21M5.6 5.6l1.8 1.8M16.6 16.6l1.8 1.8M18.4 5.6l-1.8 1.8M7.4 16.6l-1.8 1.8'/>`,
    ICON, { strokeWidth: 1.7 }),
  chat: svgIcon(
    `<path d='M21 11.5a8.4 8.4 0 0 1-9 8.4 8.6 8.6 0 0 1-3.9-.9L3 21l1.9-4.8A8.4 8.4 0 0 1 12 3.1a8.4 8.4 0 0 1 9 8.4z'/>`,
    ICON, { strokeWidth: 1.9 }),

  // 箭头
  chevron: svgIcon(`<path d='m9 5 7 7-7 7'/>`, CHEV, { strokeWidth: 2.4 }),
  chevronBrand: svgIcon(`<path d='m9 5 7 7-7 7'/>`, BRAND, { strokeWidth: 2.4 }),
  chevronDown: svgIcon(`<path d='m6 9 6 6 6-6'/>`, ICON, { strokeWidth: 2.6 }),

  // AI 简报
  sparkle: svgIcon(`<path d='M12 2l2.2 6.3L20.5 10l-6.3 2.2L12 18.5 9.8 12.2 3.5 10l6.3-1.7z'/>`,
    '#ffffff', { fill: true }),

  // 个人页
  check: svgIcon(`<path d='m4 12 5.5 5.5L20 6'/>`, '#13905F', { strokeWidth: 3 }),
  actMine: svgIcon(`<rect x='4' y='4' width='16' height='16' rx='3'/><path d='M9 11l2 2 4-4'/>`,
    BRAND),
  actPublish: svgIcon(`<path d='M12 5v14M5 12h14'/>`, '#C9741F'),
  menuBell: svgIcon(
    `<path d='M18 8a6 6 0 1 0-12 0c0 7-3 8-3 8h18s-3-1-3-8'/>` +
    `<path d='M13.7 21a2 2 0 0 1-3.4 0'/>`, SOFT, { strokeWidth: 1.8 }),
  menuLock: svgIcon(`<rect x='4' y='10' width='16' height='10' rx='2.4'/><path d='M8 10V7a4 4 0 0 1 8 0v3'/>`,
    SOFT, { strokeWidth: 1.8 }),
  menuHelp: svgIcon(
    `<circle cx='12' cy='12' r='8.5'/><path d='M9.6 9.4a2.5 2.5 0 0 1 4.85.8c0 1.7-2.45 2.3-2.45 3.8'/>` +
    `<path d='M12 17h.01'/>`, SOFT, { strokeWidth: 1.8 }),

  // 指南内容列表（各档底色）
  guideInfo: svgIcon(`<circle cx='12' cy='12' r='8.5'/><path d='M12 11.5v4.5'/><path d='M12 8h.01'/>`,
    BRAND),
  guideDoc: svgIcon(`<path d='M5 4h9l5 5v11H5z'/><path d='M14 4v5h5'/>`, '#0A8E86'),
  guideHelp: svgIcon(
    `<circle cx='12' cy='12' r='8.5'/><path d='M9.6 9.4a2.5 2.5 0 0 1 4.85.8c0 1.7-2.45 2.3-2.45 3.8'/>` +
    `<path d='M12 17h.01'/>`, '#C9741F'),
  guideShield: svgIcon(`<path d='M12 3l8 4v5c0 4.5-3.2 7.6-8 9-4.8-1.4-8-4.5-8-9V7z'/><path d='m9 12 2 2 4-4'/>`,
    '#6C4BD1'),

  // 筛选抽屉
  sliders: svgIcon(
    `<path d='M4 7h10M18 7h2M4 17h4M12 17h8'/>` +
    `<circle cx='16' cy='7' r='2.1'/><circle cx='10' cy='17' r='2.1'/>`, ICON),
}

export type IconName = keyof typeof ICONS
