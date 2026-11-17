import { useState } from 'react'
import { Input, ScrollView, Text, View } from '@tarojs/components'
import Taro, { useDidShow } from '@tarojs/taro'
import AppBar from '../../components/AppBar'
import TaskCard from '../../components/TaskCard'
import { ICONS } from '../../components/icons'
import { ROLES, filterTasks, getTasks, type Role } from '../../models/task'
import { syncSelectedFromRoute } from '../../models/tab'

// AI 每日简报：固定 3 条，每条对应一个可执行动作（原型 P1-4：结构化 + 两个出口）
const BRIEF_ITEMS = [
  { tone: 'warn', text: '2 个任务今日需提交进度（21:00 前）' },
  { tone: '', text: '1 份产出已提交，等待企业验收' },
  { tone: 'ok', text: '新增 5 个与你技能匹配的任务' },
]

type Chip = Role | '全部'

// 任务大厅（首页）：10 秒内找到「我能做、且值得做」的任务，主行动 = 一键认领
function Hall() {
  useDidShow(() => syncSelectedFromRoute())

  const [chip, setChip] = useState<Chip>('全部')
  const [keyword, setKeyword] = useState('')

  const list = filterTasks({ role: chip, keyword })

  const showNotice = () => {
    Taro.showToast({ title: '验收结果、催办与企业回复会在这里提醒', icon: 'none' })
  }

  const scrollToRecommend = () => {
    const query = Taro.createSelectorQuery()
    query.select('#recommend').boundingClientRect()
    query.selectViewport().scrollOffset()
    query.exec((res) => {
      const rect = res[0]
      const viewport = res[1]
      if (rect && viewport) {
        Taro.pageScrollTo({ scrollTop: viewport.scrollTop + rect.top - 60, duration: 300 })
      }
    })
  }

  return (
    <>
      <AppBar
        title='任务大厅'
        action={
          <View className='appBarBtn' style={{ backgroundImage: ICONS.bell }} onClick={showNotice}>
            <View className='badgeDot' />
          </View>
        }
      />
      <View className='pageBody withTab'>
        {/* 全局搜索：占位符即说明——搜任务、技能或企业 */}
        <View className='search'>
          <View className='searchIcon' style={{ backgroundImage: ICONS.searchMuted }} />
          <Input
            className='searchInput'
            value={keyword}
            placeholder='搜索任务、技能或企业'
            placeholderClass='searchPlaceholder'
            onInput={(event) => setKeyword(event.detail.value)}
          />
        </View>

        {/* AI 每日简报：3 条 + 去打卡 / 看推荐两个出口 */}
        <View className='brief'>
          <View className='briefTop'>
            <View className='briefEyebrow'>
              <View className='briefSpark'>
                <View className='briefSparkI' style={{ backgroundImage: ICONS.sparkle }} />
              </View>
              <Text>AI 每日简报</Text>
            </View>
            <Text className='briefTime'>08:20 自动生成</Text>
          </View>
          <Text className='briefH3'>早，析芸。今天有 3 件事</Text>
          <View className='briefList'>
            {BRIEF_ITEMS.map((item) => (
              <View className='briefItem' key={item.text}>
                <View className={`briefDot ${item.tone}`} />
                <Text className='briefText'>{item.text}</Text>
              </View>
            ))}
          </View>
          <View className='briefActs'>
            <View
              className='btnMini'
              onClick={() => Taro.switchTab({ url: '/pages/mine/index' })}
            >
              去打卡
            </View>
            <View className='btnMini ghost' onClick={scrollToRecommend}>看推荐</View>
          </View>
        </View>

        {/* 岗位快捷筛选：横向滑动，与任务库同一组岗位值 */}
        <ScrollView scrollX className='chips'>
          {(['全部', ...ROLES] as Chip[]).map((role) => (
            <View
              key={role}
              className={`chip${chip === role ? ' on' : ''}`}
              onClick={() => setChip(role)}
            >
              {role}
            </View>
          ))}
        </ScrollView>

        {/* 分区标题：排序依据 + 总数，让列表可预期 */}
        <View className='secRow' id='recommend'>
          <View className='secRowL'>
            <Text className='secRowTitle'>推荐任务</Text>
            <Text className='secRowSub'>按你的技能标签与在修课程排序</Text>
          </View>
          <View
            className='secRowR'
            onClick={() => Taro.navigateTo({ url: '/pages/library/index' })}
          >
            <Text>全部 {getTasks().length}</Text>
            <View className='secRowChev' style={{ backgroundImage: ICONS.chevronBrand }} />
          </View>
        </View>

        {list.map((task) => (
          <TaskCard key={task.id} task={task} />
        ))}

        {/* 空状态：一句解释 + 一个出口 */}
        {list.length === 0 && (
          <View className='empty'>
            <Text className='emptyText'>暂无符合条件的任务 · 换个关键词或岗位试试</Text>
            <View
              className='emptyAct'
              onClick={() => { setChip('全部'); setKeyword('') }}
            >
              看全部任务
            </View>
          </View>
        )}
      </View>
    </>
  )
}

export default Hall
