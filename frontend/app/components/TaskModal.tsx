'use client'

import { useState, useEffect } from 'react'
import { Dialog } from '@headlessui/react'
import { Task, TaskStatus, TaskPriority, TaskSuggestion } from '@/types/task'
import { Project } from '@/types/project'
import { TagSelector } from '@/components/TagSelector'
import { BoltIcon, ClockIcon } from '@heroicons/react/24/outline'
import { toast } from 'react-toastify'
import { useTaskService } from '@/services/taskService'
import { useProjectService } from '@/services/projectService'
import { handleAPIError } from '@/utils/error'
import api from '@/services/api'

interface TaskModalProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (task: Partial<Task>) => Promise<void>
  initialData?: Task
}

export default function TaskModal({ isOpen, onClose, onSubmit, initialData }: TaskModalProps) {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [status, setStatus] = useState<TaskStatus>('todo')
  const [priority, setPriority] = useState<TaskPriority>('medium')
  const [projectId, setProjectId] = useState<string | undefined>(undefined)
  const [dueDate, setDueDate] = useState('')
  const [energyLevel, setEnergyLevel] = useState(3)
  const [estimatedTime, setEstimatedTime] = useState(30)
  const [tags, setTags] = useState<string[]>([])
  const [isLoadingSuggestions, setIsLoadingSuggestions] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [projects, setProjects] = useState<Project[]>([])

  const projectService = useProjectService()

  useEffect(() => {
    const loadProjects = async () => {
      const projects = await projectService.fetchProjects()
      setProjects(projects)
    }
    loadProjects()
  }, [])

  useEffect(() => {
    if (initialData) {
      setTitle(initialData.title)
      setDescription(initialData.description || '')
      setStatus(initialData.status)
      setPriority(initialData.priority)
      setProjectId(initialData.project_id || undefined)
      setDueDate(initialData.due_date ? new Date(initialData.due_date).toISOString().split('T')[0] : '')
      setEnergyLevel(initialData.energy_level || 3)
      setEstimatedTime(initialData.estimated_time || 30)
      setTags(initialData.tags || [])
    } else {
      // Reset form for new task
      setTitle('')
      setDescription('')
      setStatus('todo')
      setPriority('medium')
      setProjectId(undefined)
      setDueDate('')
      setEnergyLevel(3)
      setEstimatedTime(30)
      setTags([])
    }
  }, [initialData])

  // Get AI suggestions when title/description changes
  useEffect(() => {
    const getSuggestions = async () => {
      if (!title || isLoadingSuggestions || initialData) return

      try {
        setIsLoadingSuggestions(true)
        const { data } = await api.post<TaskSuggestion>('/tasks/suggest', {
          title,
          description
        })
        
        if (data) {
          setPriority(data.priority)
          setTags(data.suggested_tags)
          setEnergyLevel(data.energy_level)
          setEstimatedTime(data.estimated_time)
        }
      } catch (error) {
        console.error('Error getting AI suggestions:', error)
      } finally {
        setIsLoadingSuggestions(false)
      }
    }

    const debounceTimer = setTimeout(() => {
      getSuggestions()
    }, 500)

    return () => clearTimeout(debounceTimer)
  }, [title, description, isLoadingSuggestions, initialData])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    try {
      setIsSubmitting(true)
      
      const taskData: Partial<Task> = {
        title,
        description,
        status,
        priority,
        project_id: projectId,
        due_date: dueDate ? new Date(dueDate + 'T23:59:59').toISOString() : undefined,
        energy_level: energyLevel,
        estimated_time: estimatedTime,
        tags
      }

      await onSubmit(taskData)
      onClose()
    } catch (error) {
      showError(handleAPIError(error))
    } finally {
      setIsSubmitting(false)
    }
  }

  const showError = (message: string) => toast.error(message)
  const showSuccess = (message: string) => toast.success(message)

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30 dark:bg-black/50" aria-hidden="true" />
      
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-xl w-full rounded-lg bg-white dark:bg-gray-800 p-6 shadow-xl">
          <Dialog.Title className="text-lg font-medium text-gray-900 dark:text-white mb-4">
            {initialData ? 'Edit Task' : 'New Task'}
          </Dialog.Title>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Title field */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Title</label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                required
              />
            </div>

            {/* Description field */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Description</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                rows={3}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Status, Priority and Project */}
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Status</label>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as TaskStatus)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                  <option value="todo">Todo</option>
                  <option value="in_progress">In Progress</option>
                  <option value="done">Done</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Priority</label>
                <select
                  value={priority}
                  onChange={(e) => setPriority(e.target.value as TaskPriority)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Project (Optional)</label>
                <select
                  value={projectId || ''}
                  onChange={(e) => setProjectId(e.target.value || undefined)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                  <option value="">No Project</option>
                  {projects.map((project) => (
                    <option key={project.id} value={project.id}>
                      {project.title}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Due Date and Energy Level */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Due Date</label>
                <input
                  type="date"
                  value={dueDate}
                  onChange={(e) => setDueDate(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  <BoltIcon className="w-4 h-4 inline mr-1" />
                  Energy Level (1-5)
                </label>
                <input
                  type="range"
                  min="1"
                  max="5"
                  value={energyLevel}
                  onChange={(e) => setEnergyLevel(parseInt(e.target.value))}
                  className="mt-1 block w-full"
                />
                <div className="flex justify-between text-xs text-gray-500 dark:text-gray-400">
                  <span>Low</span>
                  <span>High</span>
                </div>
              </div>
            </div>

            {/* Estimated Time */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                <ClockIcon className="w-4 h-4 inline mr-1" />
                Estimated Time (minutes)
              </label>
              <input
                type="number"
                value={estimatedTime}
                onChange={(e) => setEstimatedTime(parseInt(e.target.value))}
                min="1"
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Tag Selector */}
            <TagSelector
              selectedTags={tags}
              onChange={setTags}
              className="mt-4"
            />

            {/* AI Suggestions Loading State */}
            {isLoadingSuggestions && (
              <div className="text-sm text-gray-500 dark:text-gray-400 animate-pulse">
                Getting AI suggestions...
              </div>
            )}

            {/* Action Buttons */}
            <div className="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3">
              <button
                type="submit"
                disabled={isSubmitting}
                className="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:text-sm dark:hover:bg-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSubmitting ? 'Saving...' : initialData ? 'Update Task' : 'Create Task'}
              </button>
              <button
                type="button"
                onClick={onClose}
                disabled={isSubmitting}
                className="mt-3 inline-flex justify-center rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-base font-medium text-gray-700 dark:text-gray-200 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:mt-0 sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Cancel
              </button>
            </div>
          </form>
        </Dialog.Panel>
      </div>
    </Dialog>
  )
}