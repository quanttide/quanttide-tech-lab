import { Text, View } from '@tarojs/components'
import Taro, { useDidShow } from '@tarojs/taro'
import AppBar from '../../components/AppBar'
import { ICONS } from '../../components/icons'
import { syncSelectedFromRoute } from '../../models/tab'

// 能力标签：实战反推技能——已点亮为蓝，未点亮置灰给成长路径（原型 P3-6）
const SKILLS = [
  { label: '竞品分析', tone: '' },
  { label: '用户访谈', tone: '' },
  { label: '需求文档', tone: '' },
  { label: '数据分析', tone: 'green' },
  { label: '待点亮：原型设计', tone: 'gray' },
]

// 设置列表：按频率排序，每项右侧一句用途（原型 P3-7；隐私入口必须可达）
const MENU = [
  { icon: 'menuBell', title: '消息通知', desc: '验收结果、任务催办' },
  { icon: 'menuLock', title: '隐私与数据', desc: '授权范围、数据导出' },
  { icon: 'menuHelp', title: '帮助与反馈', desc: '问题反馈 24 小时内回复' },
] as const

const notReady = (what: string) => () =>
  Taro.showToast({ title: `${what}：登录与任务记录接通后开放`, icon: 'none' })

// 个人：3 秒内知道「我有几件事要处理」，主行动 = 进入我的接单
function Mine() {
  useDidShow(() => syncSelectedFromRoute())

  const copyId = () => {
    Taro.setClipboardData({
      data: '12335646475',
      success: () => Taro.showToast({ title: 'ID 已复制', icon: 'none' }),
    })
  }

  return (
    <>
      <AppBar
        title='个人'
        action={
          <View
            className='appBarBtn'
            style={{ backgroundImage: ICONS.gear }}
            onClick={notReady('设置')}
          />
        }
      />
      <View className='pageBody withTab'>
        {/* 名片：身份 + 认证 + 资料完成度 */}
        <View className='profile'>
          <View className='pfTop'>
            <View className='avatar'>罗</View>
            <View className='pfIdBox'>
              <View className='pfNameRow'>
                <Text className='pfName'>罗析芸</Text>
                <Text className='verify'>学生认证</Text>
              </View>
              <Text className='pfId' onClick={copyId}>ID 12335646475 · 点按复制</Text>
            </View>
            <View className='pfEdit' onClick={notReady('完善资料')}>完善资料 80%</View>
          </View>

          <View className='pills'>
            <View className='pill ok'>
              <View className='pillCheck' style={{ backgroundImage: ICONS.check }} />
              <Text>学生 · 可接全部任务</Text>
            </View>
            <Text className='pill'>浙江大学 · 计算机学院</Text>
            <Text className='pill'>2024 级</Text>
          </View>

          <View className='stats'>
            <View className='stat'>
              <Text className='statB'>12</Text>
              <Text className='statS'>累计接单</Text>
            </View>
            <View className='stat'>
              <Text className='statB'>92%</Text>
              <Text className='statS'>按期完成率</Text>
            </View>
            <View className='stat'>
              <Text className='statB'>4.8</Text>
              <Text className='statS'>企业评分</Text>
            </View>
          </View>
        </View>

        {/* 双向身份：接单 / 发布同权重并列 */}
        <View className='actions'>
          <View className='act' onClick={notReady('我的接单')}>
            <View className='actI'>
              <View className='actIcon' style={{ backgroundImage: ICONS.actMine }} />
            </View>
            <Text className='actB'>我的接单</Text>
            <Text className='actS'>进行中 3 · 待验收 1</Text>
            <View className='actChev' style={{ backgroundImage: ICONS.chevron }} />
          </View>
          <View className='act' onClick={notReady('我的发布')}>
            <View className='actI actI-orange'>
              <View className='actIcon' style={{ backgroundImage: ICONS.actPublish }} />
            </View>
            <Text className='actB'>我的发布</Text>
            <Text className='actS'>待处理 2 · 待验收 1</Text>
            <View className='actChev' style={{ backgroundImage: ICONS.chevron }} />
          </View>
        </View>

        {/* 能力标签：留下来持续接单的核心激励 */}
        <View className='skillWrap'>
          <View className='skillHead'>
            <Text className='skillB'>能力标签</Text>
            <Text className='skillS'>来自 12 次实战 · 可写入简历</Text>
          </View>
          <View className='skills'>
            {SKILLS.map((skill) => (
              <Text key={skill.label} className={`skill ${skill.tone}`}>
                {skill.label}
              </Text>
            ))}
          </View>
        </View>

        <View className='menu'>
          {MENU.map((row) => (
            <View className='mrow' key={row.title} onClick={notReady(row.title)}>
              <View className='mi'>
                <View className='miIcon' style={{ backgroundImage: ICONS[row.icon] }} />
              </View>
              <View className='mt'>
                <Text className='mtB'>{row.title}</Text>
                <Text className='mtS'>{row.desc}</Text>
              </View>
              <View className='mChev' style={{ backgroundImage: ICONS.chevron }} />
            </View>
          ))}
        </View>
      </View>
    </>
  )
}

export default Mine
