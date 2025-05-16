'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { FiSend, FiTrash2, FiCheck, FiBookmark } from 'react-icons/fi'
import { MdCheckBox, MdCheckBoxOutlineBlank } from 'react-icons/md'
import { chatService, ChatMessage, ChatResponse } from '../services/chatService'
import { useAuth } from '../contexts/AuthContext'
import { usePrompt } from '../contexts/PromptContext'
import { Button } from '@/components/ui/button'
import { useToast } from '@/hooks/use-toast'
import SavedPrompts from './SavedPrompts'

interface Message {
  role: 'user' | 'assistant'
  content: string
  tags?: string[]
  id?: string // ID único para identificar mensagens no histórico
  selected?: boolean // Propriedade para rastrear seleção
}

export default function Chat() {
  const router = useRouter()
  const { user, loading: authLoading } = useAuth()
  const { getConversationContext } = usePrompt()
  const { toast } = useToast()
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [isSelectionMode, setIsSelectionMode] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [showSavedPrompts, setShowSavedPrompts] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!authLoading && !user) router.push('/login')
  }, [authLoading, user, router])

  // Carregar histórico inicial do chat
  useEffect(() => {
    const loadChatHistory = async () => {
      try {
        const history = await chatService.getChatHistory()
        const formattedMessages: Message[] = history.flatMap(entry => ([
          { 
            role: 'user' as const, 
            content: entry.user_message,
            tags: entry.tags,
            id: `user-${entry.id}`,
            selected: false
          },
          { 
            role: 'assistant' as const, 
            content: entry.ai_response,
            tags: entry.tags,
            id: `assistant-${entry.id}`,
            selected: false
          }
        ]))
        setMessages(formattedMessages)
      } catch (error) {
        console.error('Error loading chat history:', error)
      } finally {
        setIsLoading(false)
      }
    }

    if (user) {
      loadChatHistory()
    }
  }, [user])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = async () => {
    if (authLoading || !user || !input.trim()) return

    const userMessage: Message = { 
      role: 'user', 
      content: input,
      id: `temp-user-${Date.now()}`,
      selected: false
    }
    setMessages(prev => [...prev, userMessage])
    setInput('')
    setIsLoading(true)

    try {
      const request: ChatMessage = { 
        message: input,
        context: {
          conversation: getConversationContext(messages)
        }
      }
      const response = await chatService.sendMessage(request)
      const assistantMessage: Message = { 
        role: 'assistant', 
        content: response.message,
        tags: response.suggestions,
        id: response.context?.history_id ? `assistant-${response.context.history_id}` : `temp-assistant-${Date.now()}`,
        selected: false
      }
      setMessages(prev => [...prev, assistantMessage])
    } catch (error) {
      console.error('Error sending message:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  // Alternar modo de seleção
  const toggleSelectionMode = () => {
    setIsSelectionMode(prev => !prev)
    // Se estamos saindo do modo de seleção, desmarque todas as mensagens
    if (isSelectionMode) {
      setMessages(messages.map(msg => ({ ...msg, selected: false })))
    }
  }

  // Alternar seleção de uma mensagem
  const toggleMessageSelection = (id: string | undefined) => {
    if (!id || !isSelectionMode) return
    
    setMessages(messages.map(msg => 
      msg.id === id ? { ...msg, selected: !msg.selected } : msg
    ))
  }

  // Selecionar ou desselecionar todas as mensagens
  const toggleSelectAll = () => {
    const areAllSelected = messages.every(msg => msg.selected)
    setMessages(messages.map(msg => ({ ...msg, selected: !areAllSelected })))
  }

  // Excluir mensagens selecionadas
  const deleteSelectedMessages = async () => {
    const selectedIds = messages
      .filter(msg => msg.selected)
      .map(msg => msg.id?.split('-')[1]) // Extrair apenas o ID sem o prefixo
      .filter(Boolean) // Remover undefined
      
    if (selectedIds.length === 0) return
    
    setIsDeleting(true)
    
    try {
      // Agrupar IDs por pares (user/assistant) baseados na mesma conversa
      const uniqueIds = Array.from(new Set(selectedIds))
      
      // Chamar a API para apagar as mensagens
      await chatService.deleteChatMessages(uniqueIds as string[])
      
      // Remover mensagens da interface
      setMessages(messages.filter(msg => !msg.selected))
      
      // Sair do modo de seleção
      setIsSelectionMode(false)
      
      toast({
        title: "Mensagens excluídas",
        description: `${uniqueIds.length} mensagens foram removidas do histórico.`,
      })
    } catch (error) {
      console.error('Error deleting messages:', error)
      toast({
        title: "Erro ao excluir mensagens",
        description: "Não foi possível excluir as mensagens selecionadas.",
        variant: "destructive",
      })
    } finally {
      setIsDeleting(false)
    }
  }

  // Usar um prompt salvo
  const handleSelectPrompt = (promptText: string) => {
    setInput(promptText)
    setShowSavedPrompts(false)
  }

  // Salvar o prompt atual
  const handleSaveCurrentPrompt = async () => {
    if (!input.trim()) return
    
    try {
      await chatService.savePrompt(input)
      toast({
        title: "Prompt salvo",
        description: "O prompt atual foi salvo com sucesso.",
      })
    } catch (error) {
      console.error('Error saving prompt:', error)
      toast({
        title: "Erro ao salvar prompt",
        description: "Não foi possível salvar o prompt.",
        variant: "destructive",
      })
    }
  }

  const getSelectedCount = () => {
    return messages.filter(msg => msg.selected).length
  }

  if (authLoading || (isLoading && messages.length === 0)) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-blue-500 border-t-transparent"></div>
      </div>
    )
  }

  return (
    <div className="h-full flex flex-col">
      {/* Barra de ferramentas do chat */}
      <div className="flex justify-between items-center mb-3">
        <h2 className="text-lg font-semibold">Chat</h2>
        <div className="flex gap-2">
          {isSelectionMode && (
            <>
              <Button 
                variant="outline" 
                size="sm"
                onClick={toggleSelectAll}
                disabled={messages.length === 0}
              >
                {messages.every(msg => msg.selected) ? 'Desmarcar Todos' : 'Selecionar Todos'}
              </Button>
              <Button 
                variant="destructive" 
                size="sm"
                onClick={deleteSelectedMessages}
                disabled={getSelectedCount() === 0 || isDeleting}
              >
                {isDeleting ? (
                  <div className="animate-spin h-4 w-4 border-2 border-white rounded-full border-t-transparent mr-1"></div>
                ) : (
                  <FiTrash2 className="mr-1" />
                )}
                Excluir ({getSelectedCount()})
              </Button>
            </>
          )}
          <Button 
            variant={isSelectionMode ? "secondary" : "outline"} 
            size="sm"
            onClick={toggleSelectionMode}
          >
            {isSelectionMode ? (
              <>
                <FiCheck className="mr-1" />
                Concluir
              </>
            ) : (
              <>
                <MdCheckBoxOutlineBlank className="mr-1" />
                Selecionar
              </>
            )}
          </Button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-600">
        <div className="space-y-4">
          {messages.map((message, index) => (
            <div
              key={message.id || index}
              className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
              onClick={() => toggleMessageSelection(message.id)}
            >
              <div
                className={`relative max-w-[70%] p-3 rounded-lg ${
                  message.role === 'user' 
                    ? 'bg-blue-50 dark:bg-blue-900/50' 
                    : 'bg-gray-50 dark:bg-gray-700'
                } ${isSelectionMode ? 'cursor-pointer hover:opacity-90' : ''} ${
                  message.selected ? 'ring-2 ring-blue-500 dark:ring-blue-400' : ''
                }`}
              >
                {isSelectionMode && (
                  <div className="absolute top-2 right-2">
                    {message.selected ? (
                      <MdCheckBox className="text-blue-500 text-lg" />
                    ) : (
                      <MdCheckBoxOutlineBlank className="text-gray-400 text-lg" />
                    )}
                  </div>
                )}
                <div className="prose dark:prose-invert max-w-none">
                  <p className="whitespace-pre-line m-0">{message.content}</p>
                </div>
                {message.tags && message.tags.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-1">
                    {message.tags.map((tag, i) => (
                      <span
                        key={i}
                        className="inline-block px-2 py-1 text-xs rounded bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-100"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="p-3 rounded-lg bg-gray-50 dark:bg-gray-700">
                <div className="animate-spin h-4 w-4 border-2 border-blue-500 rounded-full border-t-transparent"></div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* Componente de Prompts Salvos */}
      {showSavedPrompts && (
        <div className="mt-2 mb-2">
          <SavedPrompts onSelectPrompt={handleSelectPrompt} />
        </div>
      )}

      <div className="mt-4">
        <div className="flex justify-between items-center mb-2">
          <Button
            variant="ghost" 
            size="sm"
            onClick={() => setShowSavedPrompts(!showSavedPrompts)}
            className="text-sm flex items-center text-gray-600 dark:text-gray-400"
          >
            <FiBookmark className="mr-1" />
            {showSavedPrompts ? 'Ocultar Prompts' : 'Prompts Salvos'}
          </Button>
          
          {input.trim() && (
            <Button
              variant="outline" 
              size="sm"
              onClick={handleSaveCurrentPrompt}
              className="text-sm"
            >
              Salvar Prompt Atual
            </Button>
          )}
        </div>
        
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Digite sua mensagem..."
            disabled={isLoading || isSelectionMode}
            className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
          />
          <button
            onClick={handleSend}
            disabled={isLoading || !input.trim() || isSelectionMode}
            className="px-4 py-2 bg-blue-600 text-white rounded-md shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 flex items-center"
          >
            {isLoading ? (
              <div className="animate-spin h-4 w-4 border-2 border-white rounded-full border-t-transparent mr-2"></div>
            ) : (
              <FiSend className="mr-2" />
            )}
            Enviar
          </button>
        </div>
      </div>
    </div>
  )
}