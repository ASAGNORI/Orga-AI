import { create } from 'zustand'
import { Task } from '@/types'
import { createContext, useContext, ReactNode } from 'react'
import api from '@/services/api'

export interface TaskStats {
  total: number
  completed: number
  overdue: number
  dueToday: number
  dueThisWeek: number
  byPriority: {
    high: number
    medium: number
    low: number
  }
  byTag: Record<string, number>
}

interface TaskStore {
  tasks: Task[]
  isLoading: boolean
  error: string | null
  taskStats: TaskStats
  setTasks: (tasks: Task[]) => void
  addTask: (task: Task) => void
  updateTask: (taskId: string, task: Partial<Task>) => void
  deleteTask: (taskId: string) => void
  setIsLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  setTaskStats: (stats: TaskStats) => void
  fetchTaskStats: () => Promise<void>
}

export const useTaskStore = create<TaskStore>((set) => ({
  tasks: [],
  isLoading: false,
  error: null,
  taskStats: {
    total: 0,
    completed: 0,
    overdue: 0,
    dueToday: 0,
    dueThisWeek: 0,
    byPriority: {
      high: 0,
      medium: 0,
      low: 0
    },
    byTag: {}
  },
  setTasks: (tasks) => set({ tasks, isLoading: false, error: null }),
  addTask: (task) => set((state) => ({ tasks: [...state.tasks, task] })),
  updateTask: (taskId, updatedTask) => 
    set((state) => ({
      tasks: state.tasks.map((task) => 
        task.id === taskId ? { ...task, ...updatedTask } : task
      )
    })),
  setTaskStats: (stats) => set({ taskStats: stats }),
  deleteTask: (taskId) => 
    set((state) => ({
      tasks: state.tasks.filter((task) => task.id !== taskId)
    })),
  setIsLoading: (loading) => set({ isLoading: loading }),
  setError: (error) => set({ error, isLoading: false }),
  fetchTaskStats: async () => {
    try {
      const { data: stats } = await api.get<TaskStats>('/api/v1/tasks/stats')
      set({ taskStats: stats })
    } catch (error: any) {
      console.error('Erro ao buscar estatísticas:', error)
      // Em caso de erro, mantém as estatísticas zeradas
      set({
        taskStats: {
          total: 0,
          completed: 0,
          overdue: 0,
          dueToday: 0,
          dueThisWeek: 0,
          byPriority: { high: 0, medium: 0, low: 0 },
          byTag: {}
        }
      })
    }
  }
}))

const TaskStoreContext = createContext<TaskStore | null>(null)

export function TaskStoreProvider({ children }: { children: ReactNode }) {
  return (
    <TaskStoreContext.Provider value={useTaskStore()}>
      {children}
    </TaskStoreContext.Provider>
  )
}

export function useTaskContext() {
  const context = useContext(TaskStoreContext)
  if (!context) {
    throw new Error('useTaskContext must be used within a TaskStoreProvider')
  }
  return context
}