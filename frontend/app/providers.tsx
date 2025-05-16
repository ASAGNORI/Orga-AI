'use client'

import { ThemeProvider } from 'next-themes'
import { ToastContainer } from 'react-toastify'
import { AuthProvider } from './contexts/AuthContext'
import { PromptProvider } from './contexts/PromptContext'
import 'react-toastify/dist/ReactToastify.css'

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <AuthProvider>
        <PromptProvider>
          {children}
          <ToastContainer />
        </PromptProvider>
      </AuthProvider>
    </ThemeProvider>
  )
}