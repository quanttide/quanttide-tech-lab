import { useState } from 'react'
import { Input, Text, View } from '@tarojs/components'
import Taro, { useDidShow } from '@tarojs/taro'
import AppBar from '../../components/AppBar'
import { ICONS } from '../../components/icons'
import { syncSelectedFromRoute } from '../../models/tab'

// 新手三步：给路径不给目录——每步一句说明（原型 P4-2）
const STEPS = [
  { n: '1', title: '注册认证', desc: '学生证认证，2 分钟' },
  { n: '2', title: '认领任务', desc: '先接一个初级任务' },
  { n: '3', title: '提交验收', desc: 'AI 初审 + 企业终审' },
]

// 全部内容：四板块统一「图标 + 标题 + 一句说明」（原型 P4-3 / P4-4）
const GUIDE_ITEMS = [
  { icon: 'guideInfo', title: '关于量潮', desc: '平台定位、合作高校与团队' },
  { icon: 'guideDoc', title: '新手入门', desc: '10 分钟走完你的第一单' },
  { icon: 'guideHelp', title: '常见问题', desc: '交付标准、验收、报酬结算' },
  { icon: 'guideShield', title: '规则章程', desc: '任务规范、信用分与违约处理' },
] as const

// 指南（Site 层 · 静态门面）：新用户 3 步之内知道怎么开始第一单
function Guide() {
  useDidShow(() => syncSelectedFromRoute())

  const [keyword, setKeyword] = useState('')

  const items = GUIDE_ITEMS.filter(
    (item) => !keyword.trim() || item.title.includes(keyword.trim()) ||
      item.desc.includes(keyword.trim()),
  )

  return (
    <>
      <AppBar
        title='指南'
        action={
          <View
            className='appBarBtn'
            style={{ backgroundImage: ICONS.chat }}
            onClick={() => Taro.showToast({ title: '助教答疑入口：问题反馈 24 小时内回复', icon: 'none' })}
          />
        }
      />
      <View className='pageBody withTab'>
        <View className='search'>
          <View className='searchIcon' style={{ backgroundImage: ICONS.searchMuted }} />
          <Input
            className='searchInput'
            value={keyword}
            placeholder='搜索指南内容'
            placeholderClass='searchPlaceholder'
            onInput={(event) => setKeyword(event.detail.value)}
          />
        </View>

        <View className='secRow'>
          <View className='secRowL'>
            <Text className='secRowTitle'>新手三步</Text>
            <Text className='secRowSub'>走完这三步就能接第一单</Text>
          </View>
        </View>

        <View className='steps'>
          {STEPS.map((step) => (
            <View className='step' key={step.n}>
              <View className='stepN'>{step.n}</View>
              <Text className='stepB'>{step.title}</Text>
              <Text className='stepS'>{step.desc}</Text>
            </View>
          ))}
        </View>

        <View className='secRow secRowSpaced'>
          <View className='secRowL'>
            <Text className='secRowTitle'>全部内容</Text>
            <Text className='secRowSub'>4 个板块 · 每项一句说明</Text>
          </View>
        </View>

        <View className='growList'>
          {items.map((item) => (
            <View
              className='grow'
              key={item.title}
              onClick={() => Taro.showToast({ title: `${item.title}：内容接通后开放`, icon: 'none' })}
            >
              <View className={`growI grow-${item.icon}`}>
                <View className='growIcon' style={{ backgroundImage: ICONS[item.icon] }} />
              </View>
              <View className='growT'>
                <Text className='growB'>{item.title}</Text>
                <Text className='growS'>{item.desc}</Text>
              </View>
              <View className='growChev' style={{ backgroundImage: ICONS.chevron }} />
            </View>
          ))}
          {items.length === 0 && (
            <Text className='emptyText'>没有匹配的指南内容 · 换个关键词试试</Text>
          )}
        </View>

        {/* 版本与更新：弱化的信息条，不与内容抢注意力（原型 P4-5） */}
        <View className='verBox'>
          <View className='verL'>
            <Text className='verB'>版本 v0.3.1</Text>
            <Text className='verS'>最近更新：11-12 新增信用分说明</Text>
          </View>
          <View
            className='verR'
            onClick={() => Taro.showToast({ title: 'v0.3.1：11-12 新增信用分说明', icon: 'none' })}
          >
            <Text>更新日志</Text>
            <View className='verChev' style={{ backgroundImage: ICONS.chevron }} />
          </View>
        </View>
      </View>
    </>
  )
}

export default Guide
