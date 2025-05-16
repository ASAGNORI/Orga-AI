import { z } from 'zod'

// Task Types & Validation
export const TaskStatusEnum = {
  TODO: 'todo',
  IN_PROGRESS: 'in_progress',
  DONE: 'done',
} as const

export const TaskPriorityEnum = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
} as const

export const taskSchema = z.object({
  id: z.string().optional(),
  title: z.string().min(1, 'Title is required').max(100),
  description: z.string().max(500).optional().nullable(),
  status: z.enum(['todo', 'in_progress', 'done']),
  priority: z.enum(['low', 'medium', 'high']),
  energy_level: z.number().min(0).max(100).optional().nullable(),
  estimated_time: z.number().min(0).optional().nullable(),
  urgency_score: z.number().min(0).max(100).optional().nullable(),
  tags: z.array(z.string()).optional().nullable(),
  due_date: z.string().datetime().optional().nullable(),
  user_id: z.string().optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
})

export type Task = z.infer<typeof taskSchema>
export type TaskStatus = 'todo' | 'in_progress' | 'done'
export type TaskPriority = 'low' | 'medium' | 'high'
export type CreateTaskInput = Omit<Task, 'id' | 'user_id' | 'created_at' | 'updated_at'>

// Calendar Types & Validation
export const eventSchema = z.object({
  id: z.string().optional(),
  title: z.string().min(1, 'Title is required').max(100),
  description: z.string().max(500).optional().nullable(),
  start: z.string().datetime(),
  end: z.string().datetime(),
  color: z.string().regex(/^#[0-9A-F]{6}$/i).optional().nullable(),
  user_id: z.string().optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
})

export type Event = z.infer<typeof eventSchema>
export type CreateEventInput = Omit<Event, 'id' | 'user_id' | 'created_at' | 'updated_at'>

// User Types & Validation
export const userSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
  avatar_url: z.string().url().optional().nullable(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
})

export type User = z.infer<typeof userSchema>

// Auth Types & Validation
export const registerSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string()
    .min(8, 'A senha deve ter no mínimo 8 caracteres')
    .regex(/[A-Z]/, 'A senha deve conter pelo menos uma letra maiúscula')
    .regex(/[a-z]/, 'A senha deve conter pelo menos uma letra minúscula')
    .regex(/[0-9]/, 'A senha deve conter pelo menos um número'),
  confirmPassword: z.string(),
  name: z.string().min(1, 'Nome é obrigatório').max(100)
}).refine((data) => data.password === data.confirmPassword, {
  message: "As senhas não coincidem",
  path: ["confirmPassword"],
})

export const loginSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(1, 'A senha é obrigatória'),
})

export type RegisterFormData = z.infer<typeof registerSchema>
export type LoginFormData = z.infer<typeof loginSchema>

// API Response Types
export interface ApiResponse<T> {
  data?: T
  error?: {
    code: number
    message: string
    path?: string
  }
}