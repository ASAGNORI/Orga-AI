import { Task, CreateTaskInput } from '@/types'
import api from '@/services/api';
import { useStore } from '@/store'
import { handleAPIError } from '@/utils/error'

const TASKS_PATH = '/api/v1/tasks'

type TaskServiceDeps = {
  setTasks: (tasks: Task[]) => void
  addTask: (task: Task) => void
  updateTask: (taskId: string, task: Task) => void
  deleteTask: (taskId: string) => void
  setIsLoading: (loading: boolean) => void
  setError: (error: string | null) => void
}

// Factory function that creates taskService instance with dependencies
export const createTaskService = (deps: TaskServiceDeps) => ({
  async fetchTasks(): Promise<Task[]> {
    try {
      deps.setIsLoading(true)
      // Get token for debugging
      const token = localStorage.getItem('auth_token') || sessionStorage.getItem('auth_token') || 'no-token-found'
      console.log('[DEBUG] Auth token (first 20 chars):', token.substring(0, 20) + '...')
      
      console.log('[DEBUG] Fetching tasks from:', TASKS_PATH)
      const response = await api.get<Task[]>(TASKS_PATH)
      console.log('[DEBUG] Tasks API response:', response)
      const { data: tasks } = response
      console.log('[DEBUG] Tasks received:', tasks ? tasks.length : 0, 'tasks')
      
      deps.setTasks(tasks)
      return tasks
    } catch (error: any) {
      console.error('[DEBUG] Error fetching tasks:', error)
      // Log more details about the error
      if (error.response) {
        // The request was made and the server responded with a status code outside of 2xx
        console.error('[DEBUG] Error response data:', error.response.data)
        console.error('[DEBUG] Error response status:', error.response.status)
        console.error('[DEBUG] Error response headers:', error.response.headers)
      }
      const message = handleAPIError(error)
      console.error('[DEBUG] Formatted error message:', message)
      deps.setError(message)
      return []
    } finally {
      deps.setIsLoading(false)
    }
  },

  async createTask(taskData: CreateTaskInput): Promise<Task | null> {
    try {
      deps.setIsLoading(true)
      const { data: task } = await api.post<Task>(TASKS_PATH, taskData)
      deps.addTask(task)
      return task
    } catch (error: any) {
      const message = handleAPIError(error)
      deps.setError(message)
      return null
    } finally {
      deps.setIsLoading(false)
    }
  },

  async updateTask(taskId: string, updates: Partial<Task>): Promise<Task | null> {
    try {
      deps.setIsLoading(true)
      const { data: task } = await api.put<Task>(`${TASKS_PATH}/${taskId}`, updates)
      deps.updateTask(taskId, task)
      return task
    } catch (error: any) {
      const message = handleAPIError(error)
      deps.setError(message)
      return null
    } finally {
      deps.setIsLoading(false)
    }
  },

  async deleteTask(taskId: string): Promise<boolean> {
    try {
      deps.setIsLoading(true)
      await api.delete(`${TASKS_PATH}/${taskId}`)
      deps.deleteTask(taskId)
      return true
    } catch (error: any) {
      const message = handleAPIError(error)
      deps.setError(message)
      return false
    } finally {
      deps.setIsLoading(false)
    }
  },
  
  // Otimização: Atualiza o status de uma tarefa sem recarregar tudo
  async updateTaskStatus(taskId: string, status: Task['status']): Promise<boolean> {
    try {
      const { data: task } = await api.put<Task>(`${TASKS_PATH}/${taskId}`, { status })
      deps.updateTask(taskId, task)
      return true
    } catch (error: any) {
      const message = handleAPIError(error)
      deps.setError(message)
      return false
    }
  }
})

// Hook to use taskService with store integration
export const useTaskService = () => {
  const store = useStore()
  return createTaskService({
    setTasks: store.setTasks,
    addTask: store.addTask,
    updateTask: store.updateTask,
    deleteTask: store.deleteTask,
    setIsLoading: store.setIsLoading,
    setError: store.setError
  })
}