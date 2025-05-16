'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '../hooks/useAuth'

export default function DashboardHeader() {
  const { user } = useAuth()
  const [greeting, setGreeting] = useState<string>('')

  // Determina a saudação com base na hora do dia
  useEffect(() => {
    const getGreeting = () => {
      const hour = new Date().getHours()
      
      if (hour >= 5 && hour < 12) {
        return 'Bom dia'
      } else if (hour >= 12 && hour < 18) {
        return 'Boa tarde'
      } else {
        return 'Boa noite'
      }
    }
    
    setGreeting(getGreeting())
    
    // Atualiza a saudação a cada minuto
    const interval = setInterval(() => {
      setGreeting(getGreeting())
    }, 60000)
    
    return () => clearInterval(interval)
  }, [])

  if (!user) {
    return null
  }

  // Extrai o primeiro nome do usuário
  const firstName = user?.full_name?.split(' ')[0] || user?.email?.split('@')[0] || 'Usuário'

  return (
    <div className="sticky top-0 z-10 flex justify-between items-center p-4 bg-white dark:bg-gray-800 shadow-sm mb-4 border-b border-gray-200 dark:border-gray-700">
      {/* Lado esquerdo vazio para manter o layout - pode ser usado para botões ou ícones futuros */}
      <div className="text-xl font-semibold text-gray-800 dark:text-white invisible">
        {/* Espaço reservado para manter o equilíbrio do flex */}
      </div>
      
      {/* Saudação centralizada e maior */}
      <div className="text-center absolute left-1/2 transform -translate-x-1/2">
        <h1 className="text-xl font-semibold text-gray-800 dark:text-white">Dashboard</h1>
      </div>
      
      {/* Saudação à direita */}
      <div className="text-right">
        <p className="text-gray-600 dark:text-gray-300 font-medium">
          {greeting}, <span className="font-bold text-primary">{firstName}</span>!
        </p>
        <p className="text-xs text-gray-500 dark:text-gray-400">{new Date().toLocaleDateString('pt-BR')}</p>
      </div>
    </div>
  )
}
