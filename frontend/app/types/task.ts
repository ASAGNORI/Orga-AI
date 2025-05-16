export type TaskStatus = 'todo' | 'in_progress' | 'done';
export type TaskPriority = 'low' | 'medium' | 'high';

export interface Task {
  id?: string;
  title: string;
  description?: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  energy_level?: number | null;
  estimated_time?: number | null;
  urgency_score?: number | null;
  tags?: string[] | null;
  due_date?: string | null;
  user_id?: string;
  project_id?: string | null;
  created_at?: string;
  updated_at?: string;
}

export type CreateTaskInput = Omit<Task, 'id' | 'user_id' | 'created_at' | 'updated_at'> & {
  title: string;
  status: TaskStatus;
  priority: TaskPriority;
};

export interface TaskFilters {
  status?: Task['status'];
  priority?: Task['priority'];
  tags?: string[];
  dueDate?: 'today' | 'week' | 'month' | 'all';
  searchTerm?: string;
  projectId?: string;
}

export interface TaskSuggestion {
  priority: Task['priority'];
  energy_level: number;
  estimated_time: number;
  suggested_tags: string[];
  category: string;
}