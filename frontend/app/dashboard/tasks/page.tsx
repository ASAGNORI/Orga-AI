'use client'

import { useState, useEffect } from 'react'
import { Task, CreateTaskInput } from '@/types/task'
import TaskList from '@/components/TaskList'
import TaskModal from '@/components/TaskModal'
import { Button } from '@/components/ui/button'
import { useStore } from '@/store'
import { toast } from 'react-toastify'
import { useTaskService } from '@/services/taskService'
import { useProjectService } from '@/services/projectService'

export default function TasksPage() {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [selectedTask, setSelectedTask] = useState<Task>()
  
  const { 
    tasks,
    isLoading,
    error,
    fetchTasks,
    addTask,
    updateTask,
    deleteTask,
    setIsLoading,
    setError
  } = useStore()

  const taskService = useTaskService()
  const projectService = useProjectService()

  useEffect(() => {
    fetchTasks()
  }, [fetchTasks])

  const handleOpenModal = (task?: Task) => {
    setSelectedTask(task)
    setIsModalOpen(true)
  }

  const handleCloseModal = () => {
    setIsModalOpen(false)
    setSelectedTask(undefined)
  }

  const handleSubmit = async (taskData: Partial<Task>) => {
    try {
      setIsLoading(true)
      if (selectedTask?.id) {
        const updatedTask = await taskService.updateTask(selectedTask.id, taskData)
        if (updatedTask) {
          updateTask(selectedTask.id, updatedTask)
          toast.success('Task updated successfully')
        }
      } else {
        const newTaskInput: CreateTaskInput = {
          title: taskData.title || '',
          description: taskData.description || null,
          status: taskData.status || 'todo',
          priority: taskData.priority || 'medium',
          energy_level: taskData.energy_level || null,
          estimated_time: taskData.estimated_time || null,
          tags: taskData.tags || [],
          due_date: taskData.due_date || null,
          project_id: taskData.project_id || null
        }
        const newTask = await taskService.createTask(newTaskInput)
        if (newTask) {
          addTask(newTask)
          toast.success('Task created successfully')
        }
      }
      handleCloseModal()
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to save task'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleTaskUpdate = async (task: Task) => {
    try {
      setIsLoading(true)
      const updatedTask = await taskService.updateTask(task.id!, task)
      if (updatedTask) {
        updateTask(task.id!, updatedTask)
        toast.success('Task updated successfully')
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to update task'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleTaskDelete = async (taskId: string) => {
    try {
      setIsLoading(true)
      await taskService.deleteTask(taskId)
      deleteTask(taskId)
      toast.success('Task deleted successfully')
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to delete task'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  if (error) {
    return <div className="text-red-500">Error: {error}</div>
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Tasks</h1>
        <Button onClick={() => handleOpenModal()}>New Task</Button>
      </div>
      <div className="grid grid-cols-3 gap-4 mb-6">
        {['todo', 'in_progress', 'done'].map((status) => (
          <div key={status}>
            <h2 className="text-center capitalize">
              {status === 'todo' ? 'To Do' : 
               status === 'in_progress' ? 'In Progress' : 
               status === 'done' ? 'Done' : status}
            </h2>
            <TaskList
              onTaskClick={handleOpenModal}
              onTaskUpdate={(task) => handleTaskUpdate(task)}
              tasks={tasks.filter((t) => {
                // Validar que a tarefa existe e tem um status definido
                if (!t || !t.status) return false;
                
                // Normalizar a comparação de status
                const taskStatus = t.status.toLowerCase().replace(' ', '_');
                return taskStatus === status;
              })}
              isLoading={isLoading}
              searchTerm=""
              statusFilter={status as 'todo' | 'in_progress' | 'done'}
              priorityFilter="all"
              onTaskDelete={(taskId) => {
                if (taskId) {
                  handleTaskDelete(taskId)
                }
              }}  
            />
          </div>
        ))}
      </div>

      <TaskModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        onSubmit={handleSubmit}
        initialData={selectedTask}
      />
    </div>
  )
}