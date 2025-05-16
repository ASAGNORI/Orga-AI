import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { User } from '@supabase/supabase-js';
import { Task } from '@/types/task';
import { Event } from '@/types/calendar';
import { Project } from '@/types/project';
import api from '@/services/api';

export interface TaskStats {
  total: number;
  completed: number;
  overdue: number;
  dueToday: number;
  dueThisWeek: number;
  byPriority: {
    high: number;
    medium: number;
    low: number;
  };
  byTag: Record<string, number>;
}

interface AppState {
  // User state
  user: User | null;
  setUser: (user: User | null) => void;

  // Tasks state
  tasks: Task[];
  taskStats: TaskStats;
  setTasks: (tasks: Task[]) => void;
  addTask: (task: Task) => void;
  updateTask: (taskId: string, updates: Partial<Task>) => void;
  deleteTask: (taskId: string) => void;
  fetchTasks: () => Promise<void>;
  fetchTaskStats: () => Promise<void>;

  // Projects state
  projects: Project[];
  setProjects: (projects: Project[]) => void;
  addProject: (project: Project) => void;
  updateProject: (projectId: string, updates: Partial<Project>) => void;
  deleteProject: (projectId: string) => void;

  // Events state
  events: Event[];
  setEvents: (events: Event[]) => void;
  addEvent: (event: Event) => void;
  updateEvent: (eventId: string, updates: Partial<Event>) => void;
  deleteEvent: (eventId: string) => void;

  // UI state
  isLoading: boolean;
  setIsLoading: (loading: boolean) => void;
  error: string | null;
  setError: (error: string | null) => void;
}

const defaultTaskStats: TaskStats = {
  total: 0,
  completed: 0,
  overdue: 0,
  dueToday: 0,
  dueThisWeek: 0,
  byPriority: { high: 0, medium: 0, low: 0 },
  byTag: {},
};

export const useStore = create<AppState>()(
  persist(
    (set, get) => ({
      // User state
      user: null,
      setUser: (user) => set({ user }),

      // Tasks state
      tasks: [],
      taskStats: defaultTaskStats,
      setTasks: (tasks) => set({ tasks }),
      addTask: (task) => {
        set((state) => ({ tasks: [task, ...state.tasks] }));
        get().fetchTaskStats();
      },
      updateTask: (taskId, updates) => {
        set((state) => ({
          tasks: state.tasks.map((task) =>
            task.id === taskId ? { ...task, ...updates } : task
          ),
        }));
        get().fetchTaskStats();
      },
      deleteTask: (taskId) => {
        set((state) => ({
          tasks: state.tasks.filter((task) => task.id !== taskId),
        }));
        get().fetchTaskStats();
      },
      fetchTasks: async () => {
        try {
          set({ isLoading: true });
          // Get token for debugging
          const token = localStorage.getItem('auth_token') || sessionStorage.getItem('auth_token') || 'no-token-found'
          console.log('[DEBUG] Store: Auth token (first 20 chars):', token.substring(0, 20) + '...')
          
          console.log('[DEBUG] Store: Fetching tasks from API...')
          const response = await api.get<Task[]>('/api/v1/tasks');
          console.log('[DEBUG] Store: Tasks API response:', response)
          const { data: tasks } = response;
          console.log('[DEBUG] Store: Tasks received:', tasks ? tasks.length : 0, 'tasks')
          
          set({ tasks });
          await get().fetchTaskStats();
        } catch (error: any) {
          console.error('[DEBUG] Store: Error fetching tasks:', error);
          // Log more details about the error
          if (error.response) {
            // The request was made and the server responded with a status code outside of 2xx
            console.error('[DEBUG] Store: Error response data:', error.response.data)
            console.error('[DEBUG] Store: Error response status:', error.response.status)
            console.error('[DEBUG] Store: Error response headers:', error.response.headers)
          }
          set({ error: 'Failed to fetch tasks' });
        } finally {
          set({ isLoading: false });
        }
      },
      fetchTaskStats: async () => {
        try {
          console.log('[DEBUG] Store: Fetching task stats...')
          const response = await api.get<TaskStats>('/api/v1/tasks/stats');
          console.log('[DEBUG] Store: Task stats response:', response)
          const { data } = response;
          if (data) {
            console.log('[DEBUG] Store: Task stats received:', data)
            set({ taskStats: data });
          }
        } catch (error: any) {
          console.error('[DEBUG] Store: Error fetching task stats:', error);
          if (error.response) {
            console.error('[DEBUG] Store: Error response data:', error.response.data)
            console.error('[DEBUG] Store: Error response status:', error.response.status)
          }
          // Define um estado de erro padrão para estatísticas
          set({ 
            taskStats: { 
              total: 0, 
              completed: 0, 
              overdue: 0, 
              dueToday: 0, 
              dueThisWeek: 0, 
              byPriority: { high: 0, medium: 0, low: 0 },
              byTag: {}
            },
            error: 'Failed to fetch task statistics. Using default values.' 
          });
        }
      },

      // Projects state
      projects: [],
      setProjects: (projects) => set({ projects }),
      addProject: (project) =>
        set((state) => ({ projects: [project, ...state.projects] })),
      updateProject: (projectId, updates) =>
        set((state) => ({
          projects: state.projects.map((project) =>
            project.id === projectId ? { ...project, ...updates } : project
          ),
        })),
      deleteProject: (projectId) =>
        set((state) => ({
          projects: state.projects.filter(
            (project) => project.id !== projectId
          ),
        })),

      // Events state
      events: [],
      setEvents: (events) => set({ events }),
      addEvent: (event) =>
        set((state) => ({
          events: [event, ...state.events],
        })),
      updateEvent: (eventId, updates) =>
        set((state) => ({
          events: state.events.map((event) =>
            event.id === eventId ? { ...event, ...updates } : event
          ),
        })),
      deleteEvent: (eventId) =>
        set((state) => ({
          events: state.events.filter((event) => event.id !== eventId),
        })),

      // UI state
      isLoading: false,
      setIsLoading: (loading) => set({ isLoading: loading }),
      error: null,
      setError: (error) => set({ error }),
    }),
    {
      name: 'orga-ai-storage',
      partialize: (state) => ({
        user: state.user,
        tasks: state.tasks,
        projects: state.projects,
        events: state.events,
      }),
    }
  )
);

interface TaskStore {
  tasks: Task[];
  addTask: (task: Task) => void;
  updateTask: (taskId: string, updates: Partial<Task>) => void;
  deleteTask: (taskId: string) => void;
}

const createTaskStore = (initialState: Partial<TaskStore> = {}) =>
  create<TaskStore>()((set) => ({
    tasks: initialState.tasks || [],
    addTask: (task) =>
      set((state) => ({ tasks: [...state.tasks, task] })),
    updateTask: (taskId, updates) =>
      set((state) => ({
        tasks: state.tasks.map((task) =>
          task.id === taskId ? { ...task, ...updates } : task
        ),
      })),
    deleteTask: (taskId) =>
      set((state) => ({
        tasks: state.tasks.filter((task) => task.id !== taskId),
      })),
  }));