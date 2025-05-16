'use client'

import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-900 dark:text-white">404</h1>
        <p className="mt-4 text-xl text-gray-600 dark:text-gray-300">Página não encontrada</p>
        <Link 
          href="/"
          className="mt-6 inline-block px-6 py-3 text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
        >
          Voltar para o início
        </Link>
      </div>
    </div>
  )
} 