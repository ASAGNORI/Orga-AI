'use client'

import { useEffect } from 'react'
import { Task } from '../types'
import { TagIcon } from '@heroicons/react/24/outline'
import TaskCard from './TaskCard'
import { DragDropContext, Droppable } from 'react-beautiful-dnd'
import { useStore } from '@/store'

interface TaskListProps {
  onTaskClick?: (task: Task) => void
  onTaskUpdate?: (task: Task) => void
  onTaskDelete?: (taskId: string) => void
  searchTerm?: string
  statusFilter?: 'all' | Task['status']
  priorityFilter?: 'all' | Task['priority'] 
  tasks?: Task[]
  isLoading?: boolean
}

export default function TaskList({ 
  onTaskClick, 
  onTaskUpdate,
  onTaskDelete,
  searchTerm, 
  statusFilter = 'all', 
  priorityFilter = 'all',
  tasks: propTasks,
  isLoading: propIsLoading
}: TaskListProps) {
  const store = useStore()
  const storeIsLoading = store.isLoading
  const storeTasks = store.tasks
  
  // Use props if provided, otherwise use store values
  const isLoading = propIsLoading !== undefined ? propIsLoading : storeIsLoading
  const allTasks = propTasks || storeTasks
  
  useEffect(() => {
    // Only fetch tasks if not provided via props
    if (!propTasks) {
      store.fetchTasks()
    }
  }, [store, propTasks])

  const filteredTasks = allTasks.filter((task) => {
    const matchesSearch = !searchTerm || 
      task.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (task.description?.toLowerCase() || '').includes(searchTerm.toLowerCase())

    const matchesStatus = statusFilter === 'all' || task.status === statusFilter
    const matchesPriority = priorityFilter === 'all' || task.priority === priorityFilter

    return matchesSearch && matchesStatus && matchesPriority
  })

  if (isLoading) {
    return (
      <div role="status" className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  return (
    <DragDropContext onDragEnd={() => {}}>
      <Droppable droppableId="task-list">
        {(provided) => (
          <div 
            ref={provided.innerRef}
            {...provided.droppableProps}
            className="space-y-4"
          >
            {filteredTasks.map((task, index) => (
              <TaskCard
                key={task.id}
                task={task}
                index={index}
                onClick={() => onTaskClick?.(task)}
                onUpdate={(updates) => {
                  if (task.id && updates) {
                    onTaskUpdate?.({ ...task, ...updates });
                  }
                }}
                onEdit={() => onTaskClick?.(task)}
                onDelete={task.id ? async (id) => {
                  onTaskDelete?.(id);
                  return Promise.resolve();
                } : undefined}
              />
            ))}
            {provided.placeholder}
          </div>
        )}
      </Droppable>
    </DragDropContext>
  )
}