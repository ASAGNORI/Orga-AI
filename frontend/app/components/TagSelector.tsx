'use client'

import { useState, useEffect } from 'react'
import { Tag, tagService } from '../services/tagService'
import { TagIcon, PlusIcon } from '@heroicons/react/24/outline'

interface TagSelectorProps {
  selectedTags: string[]
  onChange: (tags: string[]) => void
  className?: string
}

export function TagSelector({ selectedTags, onChange, className = '' }: TagSelectorProps) {
  const [commonTags, setCommonTags] = useState<Tag[]>([])
  const [tagInput, setTagInput] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadCommonTags()
  }, [])

  const loadCommonTags = async () => {
    try {
      setIsLoading(true)
      const tags = await tagService.getCommonTags()
      setCommonTags(tags)
    } catch (err) {
      setError('Failed to load tags')
      console.error('Error loading tags:', err)
    } finally {
      setIsLoading(false)
    }
  }

  const handleAddTag = async (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && tagInput.trim()) {
      e.preventDefault()
      const newTag = tagInput.trim().toLowerCase()
      
      if (!selectedTags.includes(newTag)) {
        const updatedTags = [...selectedTags, newTag]
        onChange(updatedTags)
        await tagService.updateTagUsage(newTag)
        await loadCommonTags() // Recarrega as tags comuns após adicionar uma nova
      }
      
      setTagInput('')
    }
  }

  const handleSelectTag = async (tagName: string) => {
    if (!selectedTags.includes(tagName)) {
      const updatedTags = [...selectedTags, tagName]
      onChange(updatedTags)
      await tagService.updateTagUsage(tagName)
      await loadCommonTags()
    }
  }

  const handleRemoveTag = (tagToRemove: string) => {
    const updatedTags = selectedTags.filter(tag => tag !== tagToRemove)
    onChange(updatedTags)
  }

  return (
    <div className={className}>
      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
        <TagIcon className="w-4 h-4 inline mr-1" />
        Tags
      </label>
      
      <div className="space-y-2">
        {/* Selected Tags */}
        <div className="flex flex-wrap gap-2">
          {selectedTags.map((tag) => (
            <span
              key={tag}
              className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200"
            >
              {tag}
              <button
                type="button"
                onClick={() => handleRemoveTag(tag)}
                className="ml-1 inline-flex items-center p-0.5 text-indigo-400 hover:bg-indigo-200 dark:hover:bg-indigo-800 hover:text-indigo-500 rounded-full"
              >
                ×
              </button>
            </span>
          ))}
        </div>

        {/* Common Tags */}
        {!isLoading && commonTags.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {commonTags
              .filter(tag => !selectedTags.includes(tag.name))
              .map((tag) => (
                <button
                  key={tag.id}
                  onClick={() => handleSelectTag(tag.name)}
                  className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                  <PlusIcon className="w-3 h-3 mr-1" />
                  {tag.name}
                </button>
              ))}
          </div>
        )}

        {/* Tag Input */}
        <input
          type="text"
          value={tagInput}
          onChange={(e) => setTagInput(e.target.value)}
          onKeyDown={handleAddTag}
          placeholder="Add tag and press Enter"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-800 dark:border-gray-700 dark:text-white"
        />
      </div>

      {error && (
        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
    </div>
  )
}