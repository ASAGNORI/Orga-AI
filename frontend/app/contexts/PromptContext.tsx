'use client'

import React, { createContext, useContext } from 'react'

// Sistema prompt não visível para o usuário
const SYSTEM_PROMPT = "Você é o Orga AI, um assistente de produtividade focado em ajudar o usuário a organizar tarefas, priorizar ações e manter o foco. Seu tom é amigável, direto, com toques motivacionais. Quando necessário, faça perguntas estratégicas para entender melhor os objetivos do usuário e sugerir melhorias no plano de ação. Sempre proponha pequenos passos concretos e possíveis de realizar. Sempre verifique 'Tasks', 'Projects' e 'Calendar' para identificar as necessidades, ou agendar novas solicitações."

interface Message {
  role: 'system' | 'user' | 'assistant'
  content: string
}

interface PromptContextType {
  getSystemPrompt: () => string
  getConversationContext: (lastMessages?: Message[]) => Message[]
}

const PromptContext = createContext<PromptContextType | undefined>(undefined)

export function PromptProvider({ children }: { children: React.ReactNode }) {
  const getSystemPrompt = () => SYSTEM_PROMPT

  const getConversationContext = (lastMessages: Message[] = []): Message[] => {
    // Garantir que as mensagens do histórico tenham tipos corretos
    const typedMessages = lastMessages.map(msg => ({
      role: msg.role,
      content: msg.content
    })) as Message[]
    
    return [
      { role: 'system' as const, content: SYSTEM_PROMPT },
      ...typedMessages.slice(-5) // Mantém apenas as últimas 5 mensagens para contexto
    ]
  }

  const value: PromptContextType = {
    getSystemPrompt,
    getConversationContext
  }

  return (
    <PromptContext.Provider value={value}>
      {children}
    </PromptContext.Provider>
  )
}

export function usePrompt() {
  const context = useContext(PromptContext)
  if (context === undefined) {
    throw new Error('usePrompt must be used within a PromptProvider')
  }
  return context
}