'use client'

import { useState, useEffect } from 'react'
import { FiBookmark, FiPlus, FiTrash, FiChevronDown, FiChevronUp, FiMessageSquare } from 'react-icons/fi'
import { chatService, SavedPrompt } from '../services/chatService'
import { Button } from '@/components/ui/button'
import { useToast } from '@/hooks/use-toast'

interface SavedPromptsProps {
  onSelectPrompt: (promptText: string) => void
  className?: string
}

export default function SavedPrompts({ onSelectPrompt, className = '' }: SavedPromptsProps) {
  const { toast } = useToast()
  const [prompts, setPrompts] = useState<SavedPrompt[]>([])
  const [newPromptText, setNewPromptText] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [isAdding, setIsAdding] = useState(false)

  // Load saved prompts from the API
  useEffect(() => {
    if (isOpen) {
      loadPrompts()
    }
  }, [isOpen])

  const loadPrompts = async () => {
    setIsLoading(true)
    try {
      const data = await chatService.getSavedPrompts()
      setPrompts(data)
    } catch (error) {
      console.error('Error loading prompts:', error)
      toast({
        title: 'Erro ao carregar prompts',
        description: 'Não foi possível carregar os prompts salvos.',
        variant: 'destructive'
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleAddPrompt = async () => {
    if (!newPromptText.trim()) return
    
    setIsAdding(true)
    try {
      const newPrompt = await chatService.savePrompt(newPromptText)
      setPrompts([newPrompt, ...prompts])
      setNewPromptText('')
      toast({
        title: 'Prompt salvo',
        description: 'O prompt foi salvo com sucesso.'
      })
    } catch (error) {
      console.error('Error saving prompt:', error)
      toast({
        title: 'Erro ao salvar prompt',
        description: 'Não foi possível salvar o prompt.',
        variant: 'destructive'
      })
    } finally {
      setIsAdding(false)
    }
  }

  const handleDeletePrompt = async (id: string) => {
    try {
      await chatService.deletePrompt(id)
      setPrompts(prompts.filter(p => p.id !== id))
      toast({
        title: 'Prompt excluído',
        description: 'O prompt foi excluído com sucesso.'
      })
    } catch (error) {
      console.error('Error deleting prompt:', error)
      toast({
        title: 'Erro ao excluir prompt',
        description: 'Não foi possível excluir o prompt.',
        variant: 'destructive'
      })
    }
  }

  const handleSelectPrompt = (text: string) => {
    onSelectPrompt(text)
    setIsOpen(false)
  }

  return (
    <div className={`bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg ${className}`}>
      <button
        className="w-full flex justify-between items-center p-3 text-left"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className="flex items-center text-sm font-medium text-gray-700 dark:text-gray-300">
          <FiBookmark className="mr-2" />
          Prompts Salvos
        </span>
        {isOpen ? <FiChevronUp /> : <FiChevronDown />}
      </button>
      
      {isOpen && (
        <div className="p-3 border-t border-gray-200 dark:border-gray-700">
          {/* Formulário para adicionar novo prompt */}
          <div className="mb-4">
            <div className="flex">
              <input
                type="text"
                value={newPromptText}
                onChange={(e) => setNewPromptText(e.target.value)}
                placeholder="Digite um novo prompt para salvar..."
                className="flex-1 p-2 text-sm border border-gray-300 dark:border-gray-600 rounded-l-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
              />
              <Button 
                onClick={handleAddPrompt}
                disabled={isAdding || !newPromptText.trim()}
                className="rounded-l-none"
                size="sm"
              >
                {isAdding ? (
                  <div className="animate-spin h-4 w-4 border-2 border-white rounded-full border-t-transparent"></div>
                ) : (
                  <FiPlus />
                )}
              </Button>
            </div>
          </div>

          {/* Lista de prompts salvos */}
          <div className="space-y-2 max-h-60 overflow-y-auto">
            {isLoading ? (
              <div className="flex justify-center py-4">
                <div className="animate-spin rounded-full h-6 w-6 border-2 border-blue-500 border-t-transparent"></div>
              </div>
            ) : prompts.length === 0 ? (
              <p className="text-sm text-gray-500 dark:text-gray-400 py-2 text-center">
                Nenhum prompt salvo. Adicione um acima.
              </p>
            ) : (
              prompts.map((prompt) => (
                <div 
                  key={prompt.id} 
                  className="flex justify-between items-center p-2 hover:bg-gray-50 dark:hover:bg-gray-700 rounded"
                >
                  <button
                    className="flex-1 text-left text-sm text-gray-700 dark:text-gray-300 overflow-hidden text-ellipsis whitespace-nowrap pr-2"
                    onClick={() => handleSelectPrompt(prompt.text)}
                    title={prompt.text}
                  >
                    <span className="flex items-center">
                      <FiMessageSquare className="mr-2 flex-shrink-0" />
                      {prompt.text.length > 50 ? `${prompt.text.substring(0, 50)}...` : prompt.text}
                    </span>
                  </button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDeletePrompt(prompt.id);
                    }}
                    className="text-gray-500 hover:text-red-500 dark:text-gray-400"
                  >
                    <FiTrash />
                  </Button>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}