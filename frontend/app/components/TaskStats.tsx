'use client'

import { useEffect } from 'react'
import { toast } from 'react-toastify'
import LoadingState from './LoadingState'
import styles from '../dashboard/page.module.css'
import {
  ChartBarIcon,
  ClockIcon,
  CheckCircleIcon,
  ExclamationCircleIcon,
} from '@heroicons/react/24/outline'
import { useStore } from '@/store'
import type { TaskStats as TaskStatsType } from '@/store'

interface StatCardProps {
  title: string
  value: number | string
  icon: React.ElementType
  color: string
}

const StatCard = ({ title, value, icon: Icon, color }: StatCardProps) => (
  <div className={styles.statCard}>
    <div className={`${styles.statCardInner} ${color}`}>
      <div className="flex items-center">
        <div className="flex-shrink-0">
          <Icon className="h-6 w-6 text-gray-400 dark:text-gray-500" />
        </div>
        <div className="ml-4">
          <h3 className={styles.statLabel}>{title}</h3>
          <p className={styles.statValue}>{value}</p>
        </div>
      </div>
    </div>
  </div>
)

export default function TaskStats() {
  const { taskStats, isLoading, fetchTaskStats } = useStore()

  useEffect(() => {
    let retryCount = 0;
    const maxRetries = 3;
    const retryDelay = 1000; // 1 second

    const loadStats = async () => {
      try {
        await fetchTaskStats()
      } catch (error) {
        if (retryCount < maxRetries) {
          retryCount++;
          // Exponential backoff for retries
          setTimeout(loadStats, retryDelay * Math.pow(2, retryCount - 1));
        } else {
          toast.error('Failed to load task statistics');
        }
      }
    }

    loadStats()

    // Update stats every 30 seconds
    const interval = setInterval(loadStats, 30000)
    
    return () => {
      clearInterval(interval)
    }
  }, [fetchTaskStats])

  if (isLoading) {
    return <LoadingState type="skeleton" />
  }

  const calculateCompletionRate = () => {
    if (taskStats.total === 0) return '0%'
    const rate = Math.round((taskStats.completed / taskStats.total) * 100)
    return `${rate}%`
  }

  return (
    <div className={styles.statsGrid}>
      <StatCard
        title="Total Tasks"
        value={taskStats.total}
        icon={ChartBarIcon}
        color="border-blue-500"
      />
      <StatCard
        title="Completion Rate"
        value={calculateCompletionRate()}
        icon={CheckCircleIcon}
        color="border-green-500"
      />
      <StatCard
        title="Due Today"
        value={taskStats.dueToday}
        icon={ClockIcon}
        color="border-yellow-500"
      />
      <StatCard
        title="Overdue"
        value={taskStats.overdue}
        icon={ExclamationCircleIcon}
        color="border-red-500"
      />
    </div>
  )
}