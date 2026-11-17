import { useState } from 'react'
import { Input, Text, View } from '@tarojs/components'
import Taro, { useDidShow } from '@tarojs/taro'
import AppBar from '../../components/AppBar'
import TaskCard from '../../components/TaskCard'
import { ICONS } from '../../components/icons'
import { syncSelectedFromRoute } from '../../models/tab'
import {
  LEVELS,
  ROLES,
  SORT_LABELS,
  activeConditions,
  filterTasks,
  nextSort,
  sortTasks,
  type Level,
  type Query,
  type Role,
  type SortKey,
} from '../../models/task'

// 抽屉里的三组条件（原型 P2-4：周期 / 报酬 / 形式收进抽屉，不占首屏）
const PERIODS = [
  { value: '7', label: '7 天内' },
  { value: '14', label: '14 天内' },
]
const REWARDS = [
  { value: 500, label: '¥500 以上' },
  { value: 1000, label: '¥1000 以上' },
]
const MODES = [
  { value: '线上' as const, label: '线上' },
  { value: '线下' as const, label: '线下' },
]

// 任务库（列表 / 筛选）：用两个维度把全部任务收敛到「能接的」，主行动 = 筛选
function Library() {
  // 压入页：回写路由态——页签栏在此隐藏（h5 端挂在 App 上，靠这个开关收敛）
  useDidShow(() => syncSelectedFromRoute())

  const [keyword, setKeyword] = useState('')
  const [showSearch, setShowSearch] = useState(false)
  const [role, setRole] = useState<Role | '全部'>('全部')
  const [level, setLevel] = useState<Level | '全部'>('全部')
  const [period, setPeriod] = useState<string | null>(null)
  const [rewardAt, setRewardAt] = useState<number | null>(null)
  const [mode, setMode] = useState<'线上' | '线下' | null>(null)
  const [sort, setSort] = useState<SortKey>('latest')
  const [drawer, setDrawer] = useState(false)

  const query: Query = { keyword, role, level, period, rewardAt, mode }
  const list = sortTasks(filterTasks(query), sort)
  const conditions = activeConditions(query)
  const moreCount = [period, rewardAt, mode].filter(Boolean).length

  const goBack = () => {
    const pages = Taro.getCurrentPages()
    if (pages.length > 1) {
      Taro.navigateBack()
    } else {
      // 深链直达（无历史可退）：回任务大厅，不让用户卡住
      Taro.switchTab({ url: '/pages/hall/index' })
    }
  }

  const reset = () => {
    setRole('全部')
    setLevel('全部')
    setPeriod(null)
    setRewardAt(null)
    setMode(null)
  }

  // 已选的快捷条件在「更多」行直接可见、点一下即撤掉
  const quickChips: { label: string; clear: () => void }[] = []
  if (period) quickChips.push({ label: `${period} 天内`, clear: () => setPeriod(null) })
  if (rewardAt) quickChips.push({ label: `¥${rewardAt} 以上`, clear: () => setRewardAt(null) })
  if (mode) quickChips.push({ label: mode, clear: () => setMode(null) })

  return (
    <>
      <AppBar
        title='任务库'
        onBack={goBack}
        action={
          <View
            className='appBarBtn'
            style={{ backgroundImage: ICONS.search }}
            onClick={() => setShowSearch((value) => !value)}
          />
        }
      />
      <View className='pageBody'>
        {showSearch && (
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
        )}

        {/* 筛选区：标签旁写用途，选中态可见，默认给「全部」随时退回 */}
        <View className='filterBar'>
          <View className='frow'>
            <View className='flabel'>
              <Text className='flabelB'>岗位</Text>
              <Text className='flabelS'>决定做什么</Text>
            </View>
            <View className='fchips'>
              {(['全部', ...ROLES] as (Role | '全部')[]).map((item) => (
                <View
                  key={item}
                  className={`fchip${role === item ? ' on' : ''}`}
                  onClick={() => setRole(item)}
                >
                  {item}
                </View>
              ))}
            </View>
          </View>

          <View className='frow'>
            <View className='flabel'>
              <Text className='flabelB'>难度</Text>
              <Text className='flabelS'>决定能不能做</Text>
            </View>
            <View className='fchips'>
              {(['全部', ...LEVELS] as (Level | '全部')[]).map((item) => (
                <View
                  key={item}
                  className={`fchip${level === item ? ' on' : ''}`}
                  onClick={() => setLevel(item)}
                >
                  {item}
                </View>
              ))}
            </View>
          </View>

          <View className='frow'>
            <View className='flabel'>
              <Text className='flabelB'>更多</Text>
              <Text className='flabelS'>周期 / 报酬</Text>
            </View>
            <View className='fchips'>
              {quickChips.map((chip) => (
                <View key={chip.label} className='fchip on' onClick={chip.clear}>
                  {chip.label}
                </View>
              ))}
            </View>
            <View className='filterMore' onClick={() => setDrawer(true)}>
              <View className='filterMoreIcon' style={{ backgroundImage: ICONS.sliders }} />
              {moreCount > 0 && <Text className='filterBadge'>{moreCount}</Text>}
            </View>
          </View>
        </View>

        {/* 结果条：筛选反馈的心智锚点——总数 + 已选条件数 + 排序 */}
        <View className='resultBar'>
          <Text>
            共 <Text className='resultB'>{list.length}</Text> 个任务 · 已选 {conditions} 个条件
          </Text>
          <View className='sortBtn' onClick={() => setSort(nextSort(sort))}>
            <Text>{SORT_LABELS[sort]}</Text>
            <View className='sortChev' style={{ backgroundImage: ICONS.chevronDown }} />
          </View>
        </View>

        {list.map((task) => (
          <TaskCard key={task.id} task={task} />
        ))}

        {/* 空状态：现状 + 下一步，一个出口 */}
        {list.length === 0 && (
          <View className='empty'>
            <Text className='emptyText'>暂无符合条件的任务 · 试试放宽难度</Text>
            <View className='emptyAct' onClick={reset}>重置全部条件</View>
          </View>
        )}
      </View>

      {/* 更多筛选抽屉：遮罩与抽屉是兄弟节点，点抽屉不冒泡到遮罩 */}
      {drawer && (
        <>
          <View className='drawerMask' onClick={() => setDrawer(false)} />
          <View className='drawer'>
            <View className='drawerHead'>
              <Text className='drawerTitle'>更多筛选</Text>
              <Text className='drawerClose' onClick={() => setDrawer(false)}>收起</Text>
            </View>

            <View className='drawerGroup'>
              <Text className='drawerLabel'>周期 · 决定多久做完</Text>
              <View className='fchips'>
                <View
                  className={`fchip${!period ? ' on' : ''}`}
                  onClick={() => setPeriod(null)}
                >
                  不限
                </View>
                {PERIODS.map((item) => (
                  <View
                    key={item.value}
                    className={`fchip${period === item.value ? ' on' : ''}`}
                    onClick={() => setPeriod(item.value)}
                  >
                    {item.label}
                  </View>
                ))}
              </View>
            </View>

            <View className='drawerGroup'>
              <Text className='drawerLabel'>报酬 · 决定值不值</Text>
              <View className='fchips'>
                <View
                  className={`fchip${!rewardAt ? ' on' : ''}`}
                  onClick={() => setRewardAt(null)}
                >
                  不限
                </View>
                {REWARDS.map((item) => (
                  <View
                    key={item.value}
                    className={`fchip${rewardAt === item.value ? ' on' : ''}`}
                    onClick={() => setRewardAt(item.value)}
                  >
                    {item.label}
                  </View>
                ))}
              </View>
            </View>

            <View className='drawerGroup'>
              <Text className='drawerLabel'>形式 · 线上还是线下</Text>
              <View className='fchips'>
                <View
                  className={`fchip${!mode ? ' on' : ''}`}
                  onClick={() => setMode(null)}
                >
                  不限
                </View>
                {MODES.map((item) => (
                  <View
                    key={item.value}
                    className={`fchip${mode === item.value ? ' on' : ''}`}
                    onClick={() => setMode(item.value)}
                  >
                    {item.label}
                  </View>
                ))}
              </View>
            </View>

            <View className='drawerActs'>
              <View className='drawerReset' onClick={reset}>重置</View>
              <View className='drawerOk' onClick={() => setDrawer(false)}>
                查看 {list.length} 个任务
              </View>
            </View>
          </View>
        </>
      )}
    </>
  )
}

export default Library
