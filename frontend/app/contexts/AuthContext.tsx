"use client";

import React, { createContext, useContext, useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { login as authLogin, register as authRegister, logout as authLogout, getCurrentUser } from '../services/auth-adapter'
import { config } from '../config'

interface User {
  id: string | number;
  email: string;
  full_name: string;
}

export interface AuthContextType {
  user: User | null;
  loading: boolean;
  isLoading: boolean;
  error: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<User>;
  register: (email: string, password: string, full_name: string) => Promise<void>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updatePassword: (token: string, newPassword: string) => Promise<void>;
  getToken: () => Promise<string | null>;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()

  const checkUser = async () => {
    try {
      // Tentar recuperar token do localStorage
      const token = localStorage.getItem(config.authTokenKey);
      if (!token) {
        setLoading(false);
        return;
      }

      const response = await getCurrentUser()
      
      if (response.error) {
        if (response.error.status === 401) {
          localStorage.removeItem(config.authTokenKey);
          localStorage.removeItem('user');
          return;
        }
        throw new Error(response.error.message)
      }

      if (response.user) {
        setUser(response.user)
      }
    } catch (error: any) {
      console.error('Error checking user session:', error)
      setError(error.message || 'Erro ao verificar sessão')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    checkUser()
  }, [])

  const login = async (email: string, password: string): Promise<User> => {
    try {
      setError(null)
      setLoading(true)
      
      const response = await authLogin({ email, password })
      
      if (response.error) {
        throw new Error(response.error.message)
      }

      if (response.session?.access_token) {
        localStorage.setItem(config.authTokenKey, response.session.access_token)
      }

      if (response.user) {
        localStorage.setItem('user', JSON.stringify(response.user))
        setUser(response.user)
        router.replace('/dashboard')
        return response.user
      }

      throw new Error('Dados do usuário não encontrados')
    } catch (error: any) {
      setError(error.message || 'Erro ao fazer login')
      throw error
    } finally {
      setLoading(false)
    }
  }

  const register = async (email: string, password: string, full_name: string) => {
    try {
      setError(null)
      setLoading(true)
      
      const response = await authRegister({ email, password, full_name })
      
      if (response.error) {
        throw new Error(response.error.message)
      }

      if (response.session?.access_token) {
        localStorage.setItem(config.authTokenKey, response.session.access_token)
      }

      if (response.user) {
        localStorage.setItem('user', JSON.stringify(response.user))
        setUser(response.user)
        router.replace('/dashboard')
      } else {
        throw new Error('Erro ao criar conta')
      }
    } catch (error: any) {
      setError(error.message || 'Erro ao criar conta')
      throw error
    } finally {
      setLoading(false)
    }
  }

  const logout = async () => {
    try {
      setError(null)
      setLoading(true)
      await authLogout()
      setUser(null)
      localStorage.removeItem(config.authTokenKey)
      localStorage.removeItem('user')
      router.replace('/login')
    } catch (error: any) {
      console.error('Error during logout:', error)
      setError(error.message || 'Erro ao fazer logout')
    } finally {
      setLoading(false)
    }
  }

  const resetPassword = async (email: string) => {
    try {
      setError(null)
      setLoading(true)

      const response = await fetch(`${config.apiUrl}/auth/reset-password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.message || 'Erro ao solicitar redefinição de senha')
      }
    } catch (error: any) {
      setError(error.message || 'Erro ao solicitar redefinição de senha')
      throw error
    } finally {
      setLoading(false)
    }
  }

  const updatePassword = async (token: string, newPassword: string) => {
    try {
      setError(null)
      setLoading(true)

      const response = await fetch(`${config.apiUrl}/auth/update-password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ token, password: newPassword }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.detail || data.message || 'Erro ao atualizar senha')
      }

      // Retorna o resultado com sucesso
      return data
    } catch (error: any) {
      setError(error.message || 'Erro ao atualizar senha')
      throw error
    } finally {
      setLoading(false)
    }
  }

  const getToken = async (): Promise<string | null> => {
    try {
      const token = localStorage.getItem(config.authTokenKey)
      if (!token) {
        return null
      }
      
      // Validar token com o backend
      const response = await getCurrentUser()
      if (response.error) {
        localStorage.removeItem(config.authTokenKey)
        return null
      }
      
      return token
    } catch (error) {
      console.error('Error getting token:', error)
      return null
    }
  }

  const value = {
    user,
    loading,
    isLoading: loading,
    error,
    isAuthenticated: !!user,
    login,
    register,
    logout,
    resetPassword,
    updatePassword,
    getToken
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}