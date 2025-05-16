'use client'

import { useState, ReactNode, CSSProperties } from 'react'
import Link from 'next/link'
import '../globals.css'

// Estilo inline como fallback
const styles: Record<string, CSSProperties> = {
  container: {
    minHeight: '100vh',
    padding: '2rem',
    backgroundColor: '#ebf8ff',
  },
  header: {
    fontSize: '1.875rem',
    fontWeight: 'bold',
    marginBottom: '1.5rem',
    color: '#2c5282',
  },
  card: {
    backgroundColor: 'white',
    borderRadius: '0.5rem',
    boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
    padding: '1.5rem',
    marginBottom: '1.5rem',
  },
  cardTitle: {
    fontSize: '1.25rem',
    fontWeight: 'bold',
    marginBottom: '1rem',
    color: '#1a202c',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, 1fr)',
    gap: '1rem',
  },
  redBox: {
    backgroundColor: '#fed7d7',
    color: '#9b2c2c',
    padding: '1rem',
    borderRadius: '0.25rem',
  },
  greenBox: {
    backgroundColor: '#c6f6d5',
    color: '#276749',
    padding: '1rem',
    borderRadius: '0.25rem',
  },
  blueBox: {
    backgroundColor: '#bee3f8',
    color: '#2a4365',
    padding: '1rem',
    borderRadius: '0.25rem',
  },
  yellowBox: {
    backgroundColor: '#fefcbf',
    color: '#744210',
    padding: '1rem',
    borderRadius: '0.25rem',
  },
  buttonContainer: {
    marginTop: '1.5rem',
  },
  primaryButton: {
    backgroundColor: '#4299e1',
    color: 'white',
    padding: '0.5rem 1rem',
    borderRadius: '0.25rem',
    fontWeight: '500',
  },
  secondaryButton: {
    backgroundColor: '#e2e8f0',
    color: '#1a202c',
    padding: '0.5rem 1rem',
    borderRadius: '0.25rem',
    marginLeft: '1rem',
    fontWeight: '500',
  },
  footer: {
    textAlign: 'center',
    color: '#4a5568',
  },
};

export default function PublicTestPage() {
  return (
    <div className="min-h-screen bg-blue-100 p-8" style={styles.container}>
      <h1 className="text-3xl font-bold text-blue-800 mb-6" style={styles.header}>
        Página de Teste (Verificação de CSS)
      </h1>
      
      <div className="bg-white rounded-lg shadow-lg p-6 mb-6" style={styles.card}>
        <h2 className="text-xl font-bold text-gray-800 mb-4" style={styles.cardTitle}>
          Exemplos de Estilos
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4" style={styles.grid}>
          <div className="bg-red-100 text-red-800 p-4 rounded" style={styles.redBox}>
            Box Vermelho
          </div>
          <div className="bg-green-100 text-green-800 p-4 rounded" style={styles.greenBox}>
            Box Verde
          </div>
          <div className="bg-blue-100 text-blue-800 p-4 rounded" style={styles.blueBox}>
            Box Azul
          </div>
          <div className="bg-yellow-100 text-yellow-800 p-4 rounded" style={styles.yellowBox}>
            Box Amarelo
          </div>
        </div>
        
        <div className="mt-6" style={styles.buttonContainer}>
          <button 
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded" 
            style={styles.primaryButton}
          >
            Botão Azul
          </button>
          <button 
            className="bg-gray-200 hover:bg-gray-300 text-gray-800 px-4 py-2 rounded ml-4" 
            style={styles.secondaryButton}
          >
            Botão Cinza
          </button>
        </div>
      </div>
      
      <div className="text-center text-gray-600" style={styles.footer}>
        Esta é uma página de teste para verificar se o Tailwind CSS está funcionando corretamente.
      </div>
    </div>
  )
} 