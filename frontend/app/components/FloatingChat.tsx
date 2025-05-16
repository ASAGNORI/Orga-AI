'use client'

import { useState, useRef, useEffect } from 'react'
import { FiMessageSquare, FiX, FiMinimize2 } from 'react-icons/fi'
import { AnimatePresence, motion } from 'framer-motion'
import Chat from './Chat'

export default function FloatingChat() {
  const [isOpen, setIsOpen] = useState(false)
  const chatContainerRef = useRef<HTMLDivElement>(null)

  // Função para lidar com cliques fora do chat para fechar
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (chatContainerRef.current && !chatContainerRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    // Adiciona o listener apenas quando o chat está aberto
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isOpen])

  return (
    <div className="fixed bottom-6 right-6 z-50" ref={chatContainerRef}>
      {/* Botão flutuante para abrir o chat */}
      <AnimatePresence>
        {!isOpen && (
          <motion.button
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            className="flex items-center justify-center w-14 h-14 rounded-full bg-blue-600 hover:bg-blue-700 text-white shadow-lg transition-colors duration-200"
            onClick={() => setIsOpen(true)}
            aria-label="Abrir chat"
          >
            <FiMessageSquare size={24} />
          </motion.button>
        )}
      </AnimatePresence>

      {/* Contêiner do chat com animação */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="absolute bottom-0 right-0 w-96 h-[500px] bg-white dark:bg-gray-900 rounded-lg shadow-2xl overflow-hidden border border-gray-200 dark:border-gray-700"
          >
            {/* Cabeçalho do chat */}
            <div className="flex items-center justify-between px-4 py-2 bg-blue-600 text-white">
              <h3 className="font-medium text-sm">Assistente Orga.AI</h3>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-1 rounded-full hover:bg-blue-700 transition-colors"
                  aria-label="Minimizar chat"
                >
                  <FiMinimize2 size={16} />
                </button>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-1 rounded-full hover:bg-blue-700 transition-colors"
                  aria-label="Fechar chat"
                >
                  <FiX size={16} />
                </button>
              </div>
            </div>
            
            {/* Corpo do chat */}
            <div className="w-full h-[calc(500px-40px)] p-4">
              <Chat />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}