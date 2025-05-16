import { Task } from './task';

export type ProjectStatus = 'active' | 'completed' | 'archived';

export interface Project {
  id?: string;
  title: string;
  description?: string | null;
  status?: ProjectStatus;
  user_id?: string;
  tasks?: string[]; // Array de IDs de tasks associadas
  created_at?: string;
  updated_at?: string;
}

export type CreateProjectInput = Omit<Project, 'id' | 'user_id' | 'created_at' | 'updated_at'>;

export interface ProjectFilters {
  status?: ProjectStatus;
  searchTerm?: string;
}