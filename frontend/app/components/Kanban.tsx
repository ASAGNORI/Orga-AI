'use client'

import { useState, useEffect, useCallback } from 'react'
import { DragDropContext, Droppable } from 'react-beautiful-dnd'
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import { Task } from '../types/task'
import TaskCard from './TaskCard'
import TaskModal from './TaskModal'
import { toast } from 'react-toastify'

export default function Kanban() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [selectedTask, setSelectedTask] = useState<Task | undefined>()
  const supabase = createClientComponentClient()

  const fetchTasks = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setTasks(data || [])
    } catch (error) {
      console.error('Error fetching tasks:', error)
      toast.error('Failed to fetch tasks')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  useEffect(() => {
    fetchTasks()
  }, [fetchTasks])

  const handleCreateTask = async (taskData: Omit<Task, 'id' | 'user_id' | 'created_at' | 'updated_at'>) => {
    try {
      const { data: userData, error: userError } = await supabase.auth.getUser()
      if (userError) throw userError

      const { data, error } = await supabase
        .from('tasks')
        .insert([{ ...taskData, user_id: userData.user.id }])
        .select()
        .single()

      if (error) throw error

      setTasks((prev) => [data, ...prev])
      toast.success('Task created successfully')
    } catch (error) {
      console.error('Error creating task:', error)
      toast.error('Failed to create task')
    }
  }

  const handleUpdateTask = async (taskData: Partial<Task>) => {
    if (!selectedTask) return

    try {
      const { data, error } = await supabase
        .from('tasks')
        .update(taskData)
        .eq('id', selectedTask.id)
        .select()
        .single()

      if (error) throw error

      setTasks((prev) =>
        prev.map((task) => (task.id === selectedTask.id ? { ...task, ...data } : task))
      )
      toast.success('Task updated successfully')
    } catch (error) {
      console.error('Error updating task:', error)
      toast.error('Failed to update task')
    }
  }

  const handleDeleteTask = async (taskId: string) => {
    try {
      const { error } = await supabase.from('tasks').delete().eq('id', taskId)
      if (error) throw error

      setTasks((prev) => prev.filter((task) => task.id !== taskId))
      toast.success('Task deleted successfully')
    } catch (error) {
      console.error('Error deleting task:', error)
      toast.error('Failed to delete task')
    }
  }

  const onDragEnd = async (result: any) => {
    if (!result.destination) return

    const { source, destination } = result
    const taskId = result.draggableId
    const newStatus = destination.droppableId as Task['status']

    try {
      const { error } = await supabase
        .from('tasks')
        .update({ status: newStatus })
        .eq('id', taskId)

      if (error) throw error

      setTasks((prev) =>
        prev.map((task) => (task.id === taskId ? { ...task, status: newStatus } : task))
      )
    } catch (error) {
      console.error('Error updating task status:', error)
      toast.error('Failed to update task status')
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div 
          className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"
          aria-label="Loading tasks"
          role="status"
        ></div>
      </div>
    )
  }

  const columns = {
    todo: tasks.filter((task) => task.status === 'todo'),
    in_progress: tasks.filter((task) => task.status === 'in_progress'),
    done: tasks.filter((task) => task.status === 'done'),
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">Tasks</h1>
        <button
          onClick={() => {
            setSelectedTask(undefined)
            setIsModalOpen(true)
          }}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
        >
          New Task
        </button>
      </div>

      <DragDropContext onDragEnd={onDragEnd}>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {Object.entries(columns).map(([status, tasks]) => (
            <div key={status} className="bg-gray-50 p-4 rounded-lg">
              <h2 className="text-lg font-medium text-gray-900 mb-4 capitalize">
                {status.replace('_', ' ')}
              </h2>
              <Droppable droppableId={status}>
                {(provided) => (
                  <div
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                    className="space-y-2"
                  >
                    {tasks.map((task, index) => (
                      <TaskCard
                        key={task.id}
                        task={task}
                        index={index}
                        onEdit={(task) => {
                          setSelectedTask(task)
                          setIsModalOpen(true)
                        }}
                        onDelete={handleDeleteTask}
                      />
                    ))}
                    {provided.placeholder}
                  </div>
                )}
              </Droppable>
            </div>
          ))}
        </div>
      </DragDropContext>

      <TaskModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setSelectedTask(undefined)
        }}
        onSubmit={async (taskData) => {
          if (selectedTask) {
            await handleUpdateTask(taskData)
          } else {
            await handleCreateTask({
              title: taskData.title || '',
              description: taskData.description || '',
              status: taskData.status || 'todo',
              priority: taskData.priority || 'medium',
              energy_level: taskData.energy_level,
              estimated_time: taskData.estimated_time,
              tags: taskData.tags || [],
              due_date: taskData.due_date
            })
          }
        }}
        initialData={selectedTask}
      />
    </div>
  )
}