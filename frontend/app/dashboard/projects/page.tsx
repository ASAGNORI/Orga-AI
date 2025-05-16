'use client'

import { useState, useEffect } from 'react'
import { Task, CreateTaskInput } from '@/types/task'
import { Project } from '@/types/project'
import ProjectList from '@/components/ProjectList'
import TaskModal from '@/components/TaskModal'
import ProjectModal from '@/components/ProjectModal'
import { Button } from '@/components/ui/button'
import { useTaskService } from '@/services/taskService'
import { useProjectService } from '@/services/projectService'
import { toast } from 'react-toastify'
import { PlusIcon } from '@heroicons/react/24/outline'
import { useStore } from '@/store'

export default function ProjectsPage() {
  const [isTaskModalOpen, setIsTaskModalOpen] = useState(false)
  const [isProjectModalOpen, setIsProjectModalOpen] = useState(false)
  const [selectedTask, setSelectedTask] = useState<Task>()
  const [selectedProject, setSelectedProject] = useState<Project>()

  const {
    projects,
    tasks,
    setProjects,
    setTasks,
    addProject,
    updateProject: updateProjectStore,
    addTask,
    updateTask: updateTaskStore,
    deleteProject: deleteProjectStore,
    isLoading,
    setIsLoading,
    setError
  } = useStore()

  const taskService = useTaskService()
  const projectService = useProjectService()

  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    try {
      setIsLoading(true)
      const [projectsData, tasksData] = await Promise.all([
        projectService.fetchProjects(),
        taskService.fetchTasks()
      ])
      setProjects(projectsData)
      setTasks(tasksData)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load data'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleOpenTaskModal = (task?: Task) => {
    setSelectedTask(task)
    setIsTaskModalOpen(true)
  }

  const handleOpenProjectModal = (project?: Project) => {
    setSelectedProject(project)
    setIsProjectModalOpen(true)
  }

  const handleCloseTaskModal = () => {
    setIsTaskModalOpen(false)
    setSelectedTask(undefined)
  }

  const handleCloseProjectModal = () => {
    setIsProjectModalOpen(false)
    setSelectedProject(undefined)
  }

  const handleTaskSubmit = async (taskData: Partial<Task>) => {
    try {
      setIsLoading(true)
      if (selectedTask?.id) {
        const updatedTask = await taskService.updateTask(selectedTask.id, taskData)
        if (updatedTask) {
          updateTaskStore(selectedTask.id, updatedTask)
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
      handleCloseTaskModal()
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to save task'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleProjectSubmit = async (projectData: Partial<Project>) => {
    try {
      setIsLoading(true)
      if (selectedProject?.id) {
        const updatedProject = await projectService.updateProject(selectedProject.id, projectData)
        if (updatedProject) {
          updateProjectStore(selectedProject.id, updatedProject)
          toast.success('Project updated successfully')
        }
      } else {
        const newProject = await projectService.createProject(projectData)
        if (newProject) {
          addProject(newProject)
          toast.success('Project created successfully')
        }
      }
      handleCloseProjectModal()
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to save project'
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
        updateTaskStore(task.id!, updatedTask)
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to update task'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleProjectDelete = async (projectId: string) => {
    try {
      setIsLoading(true)
      await projectService.deleteProject(projectId)
      
      // First remove project from store
      deleteProjectStore(projectId)
      
      // Reload tasks and update store
      const tasksData = await taskService.fetchTasks()
      setTasks(tasksData)

      // Also fetch updated task statistics
      if (typeof window !== 'undefined') {
        // Get fresh instance of store to ensure we have latest state
        const store = useStore.getState()
        await store.fetchTaskStats()
      }
      
      toast.success('Project deleted successfully')
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to delete project'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  if (isLoading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/4 mb-8"></div>
          <div className="space-y-4">
            <div className="h-24 bg-gray-200 rounded"></div>
            <div className="h-24 bg-gray-200 rounded"></div>
            <div className="h-24 bg-gray-200 rounded"></div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Projects</h1>
        <div className="flex space-x-4">
          <Button onClick={() => handleOpenTaskModal()} variant="outline">
            <PlusIcon className="h-5 w-5 mr-2" />
            New Task
          </Button>
          <Button onClick={() => handleOpenProjectModal()}>
            <PlusIcon className="h-5 w-5 mr-2" />
            New Project
          </Button>
        </div>
      </div>

      <ProjectList
        projects={projects}
        tasks={tasks}
        onProjectClick={handleOpenProjectModal}
        onProjectEdit={handleOpenProjectModal}
        onProjectDelete={handleProjectDelete}
        selectedProjectId={selectedProject?.id}
      />

      <TaskModal
        isOpen={isTaskModalOpen}
        onClose={handleCloseTaskModal}
        onSubmit={handleTaskSubmit}
        initialData={selectedTask}
      />

      <ProjectModal
        isOpen={isProjectModalOpen}
        onClose={handleCloseProjectModal}
        onSubmit={handleProjectSubmit}
        initialData={selectedProject}
      />
    </div>
  )
}