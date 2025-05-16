import { type Project } from '@/types/project'
import { type Task } from '@/types/task'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { PencilIcon, TrashIcon } from '@heroicons/react/24/outline'

interface ProjectListProps {
  projects: Project[]
  tasks: Task[]
  onProjectClick?: (project: Project) => void
  onProjectEdit?: (project: Project) => void
  onProjectDelete?: (projectId: string) => void
  selectedProjectId?: string
}

export default function ProjectList({ 
  projects,
  onProjectClick,
  onProjectEdit,
  onProjectDelete,
  selectedProjectId 
}: ProjectListProps) {
  const getStatusColor = (status: Project['status']) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
      case 'completed':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'
      case 'archived':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
    }
  }

  return (
    <div className="space-y-4">
      {projects.map((project) => (
        <Card
          key={project.id}
          className={`p-4 cursor-pointer transition-all hover:shadow-md ${
            selectedProjectId === project.id 
              ? 'border-2 border-primary' 
              : 'border border-gray-200 dark:border-gray-700'
          }`}
          onClick={() => onProjectClick?.(project)}
        >
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <h3 className="text-lg font-medium">{project.title}</h3>
              {project.description && (
                <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                  {project.description}
                </p>
              )}
              <div className="mt-2">
                <Badge className={getStatusColor(project.status)}>
                  {project.status}
                </Badge>
              </div>
            </div>

            <div className="flex space-x-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={(e) => {
                  e.stopPropagation()
                  onProjectEdit?.(project)
                }}
              >
                <PencilIcon className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                className="text-red-500 hover:text-red-700 hover:bg-red-50"
                onClick={(e) => {
                  e.stopPropagation()
                  if (project.id && onProjectDelete) {
                    if (confirm('Are you sure you want to delete this project?')) {
                      onProjectDelete(project.id)
                    }
                  }
                }}
              >
                <TrashIcon className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </Card>
      ))}
    </div>
  )
}