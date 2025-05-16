'use client'

import { DragDropContext as DndContext, DropResult } from 'react-beautiful-dnd'
import { ReactNode } from 'react'
import { toast } from 'react-toastify'
import { Task } from '../types'

interface DragDropContextProps {
  children: ReactNode
  onTasksUpdate?: (tasks: Task[] | ((prevTasks: Task[]) => Task[])) => void
}

export default function DragDropContext({ children, onTasksUpdate }: DragDropContextProps) {
  const handleDragEnd = async (result: DropResult) => {
    if (!result.destination || !onTasksUpdate) return

    const destinationStatus = result.destination.droppableId as Task['status']
    const taskId = result.draggableId

    try {
      // Update local state only
      onTasksUpdate((prevTasks: Task[]) => {
        return prevTasks.map(task => {
          if (task.id === taskId) {
            return { ...task, status: destinationStatus };
          }
          return task;
        });
      });
    } catch (error) {
      showError('Failed to update task status')
      console.error('Error updating task status:', error)
    }
  }

  const showError = (message: string) => toast.error(message)

  return (
    <DndContext onDragEnd={handleDragEnd}>
      {children}
    </DndContext>
  )
}