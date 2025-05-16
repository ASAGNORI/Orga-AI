'use client'

import { Task } from '@/types/task'
import { Draggable } from 'react-beautiful-dnd'
import { PencilIcon, TrashIcon } from '@heroicons/react/24/outline'
import { formatDate } from '@/utils/date'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'

interface TaskCardProps {
  task: Task
  index: number
  onClick?: (task: Task) => void
  onUpdate?: (task: Task) => void
  onEdit?: (task: Task) => void
  onDelete?: (taskId: string) => Promise<void>
}

export default function TaskCard({ task, index, onClick, onUpdate, onEdit, onDelete }: TaskCardProps) {
  const handleStatusToggle = () => {
    if (onUpdate && task.id) {
      onUpdate({
        ...task,
        status: task.status === 'done' ? 'todo' : 'done'
      })
    }
  }

  const getPriorityColor = (priority: Task['priority']) => {
    switch (priority) {
      case 'high':
        return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
      case 'low':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
    }
  }

  return (
    <Draggable draggableId={task.id!} index={index}>
      {(provided) => (
        <div
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-4 border border-gray-200 dark:border-gray-700 hover:shadow-md transition-shadow"
        >
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={task.status === 'done'}
                  onChange={handleStatusToggle}
                  className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                />
                <h3 
                  className={`text-base font-medium ${
                    task.status === 'done' ? 'line-through text-gray-500' : ''
                  }`}
                >
                  {task.title}
                </h3>
              </div>

              {task.description && (
                <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                  {task.description}
                </p>
              )}

              <div className="mt-2 flex flex-wrap gap-2">
                <Badge
                  variant="secondary"
                  className={getPriorityColor(task.priority)}
                >
                  {task.priority}
                </Badge>

                {task.due_date && (
                  <Badge variant="outline">
                    Due {formatDate(task.due_date)}
                  </Badge>
                )}

                {task.tags?.map((tag) => (
                  <Badge key={tag} variant="secondary">
                    {tag}
                  </Badge>
                ))}
              </div>
            </div>

            <div className="flex space-x-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => onEdit?.(task)}
                className="ml-2"
              >
                <PencilIcon className="h-4 w-4" />
              </Button>
              {onDelete && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => task.id && onDelete(task.id)}
                  className="text-red-500 hover:text-red-600"
                >
                  <TrashIcon className="h-4 w-4" />
                </Button>
              )}
            </div>
          </div>
        </div>
      )}
    </Draggable>
  )
}