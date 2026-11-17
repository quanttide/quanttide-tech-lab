import { useState } from 'react'
import { Text, View } from '@tarojs/components'
import Taro from '@tarojs/taro'
import { claimTask, isClaimed, type Task } from '../models/task'

interface Props {
  task: Task
}

function formatReward(reward: number): string {
  return `¥${reward.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`
}

// 任务卡片（原型 P1-7 / P2-6 同一组件）：5 类决策信息 + 1 个行动。
// 已认领按钮变「已认领 · 去打卡」；名额耗尽按失败态给原因，不只说「操作失败」。
function TaskCard({ task }: Props) {
  const [hint, setHint] = useState('')
  const [, setTick] = useState(0)  // 认领改的是模块级快照，本地拨一下触发重渲染
  const claimed = isClaimed(task.id)
  const soldOut = task.slotsLeft <= 0

  const onClaim = () => {
    if (claimed) {
      // 已认领的任务，下一步是打卡（个人页 · 我的接单）
      Taro.switchTab({ url: '/pages/mine/index' })
      return
    }
    const result = claimTask(task.id)
    if (result === 'full') {
      setHint('名额已满 · 看看其他任务')
    } else {
      setHint('')
      Taro.showToast({ title: '已认领 · 打卡入口在「个人 · 我的接单」', icon: 'none' })
    }
    setTick((value) => value + 1)
  }

  const claimClass = claimed ? 'claim done' : soldOut ? 'claim disabled' : 'claim'
  const claimText = claimed ? '已认领 · 去打卡' : soldOut ? '名额已满' : '一键认领'

  return (
    <View className='task'>
      <View className='taskTop'>
        <View className='corp'>
          <View className={`corpLogo logo-${task.logo}`}>{task.corp.slice(0, 1)}</View>
          <Text className='corpName'>{task.corp}</Text>
          <Text className='verify'>已认证</Text>
        </View>
        <Text className='reward'>{formatReward(task.reward)}</Text>
      </View>

      <View className='taskTitle'>{task.title}</View>

      <View className='tags'>
        <Text className='tag tagRole'>{task.role}</Text>
        <Text className='tag tagLevel'>{task.level}</Text>
        <Text className='tag'>{task.mode} · {task.days} 天</Text>
      </View>

      <View className='taskFoot'>
        <Text className='meta'>
          剩 <Text className='metaB'>{task.slotsLeft}</Text>/{task.slotsTotal} 名额
        </Text>
        <Text className='meta'>{task.deadline} 截止</Text>
        <View className={claimClass} onClick={onClaim}>{claimText}</View>
      </View>

      {hint && <View className='taskHint'>{hint}</View>}
    </View>
  )
}

export default TaskCard
