import { Project } from '@/types/project'
import api from './api'
import { useCallback } from 'react'

export const useProjectService = () => {
  const fetchProjects = useCallback(async (): Promise<Project[]> => {
    try {
      const token = localStorage.getItem('auth_token') || sessionStorage.getItem('auth_token');
      if (!token) {
        throw new Error('Não autorizado. Por favor, faça login novamente.');
      }

      const response = await api.get<Project[]>('/api/v1/projects');
      return response.data;
    } catch (error: any) {
      if (error.response) {
        // Erro com resposta do servidor
        if (error.response.status === 401) {
          throw new Error('Sessão expirada. Por favor, faça login novamente.');
        }
        throw new Error(error.response.data?.message || 'Erro ao carregar projetos.');
      } else if (error.request) {
        // Erro sem resposta do servidor (problema de rede)
        throw new Error('Erro de conexão. Verifique sua internet.');
      } else {
        // Erro na configuração da requisição
        throw new Error('Erro inesperado ao carregar projetos.');
      }
    }
  }, []);

  const fetchProject = useCallback(async (id: string): Promise<Project> => {
    try {
      const response = await api.get<Project>(`/api/v1/projects/${id}`);
      return response.data;
    } catch (error: any) {
      handleApiError(error, 'Erro ao carregar projeto');
      throw error;
    }
  }, []);

  const createProject = useCallback(async (project: Partial<Project>): Promise<Project> => {
    try {
      const response = await api.post<Project>('/api/v1/projects', project);
      return response.data;
    } catch (error: any) {
      handleApiError(error, 'Erro ao criar projeto');
      throw error;
    }
  }, []);

  const updateProject = useCallback(async (id: string, project: Partial<Project>): Promise<Project> => {
    try {
      const response = await api.put<Project>(`/api/v1/projects/${id}`, project);
      return response.data;
    } catch (error: any) {
      handleApiError(error, 'Erro ao atualizar projeto');
      throw error;
    }
  }, []);

  const deleteProject = useCallback(async (id: string): Promise<void> => {
    try {
      await api.delete(`/api/v1/projects/${id}`);
    } catch (error: any) {
      handleApiError(error, 'Erro ao excluir projeto');
      throw error;
    }
  }, []);

  // Função auxiliar para tratamento de erros
  const handleApiError = (error: any, defaultMessage: string) => {
    if (error.response) {
      if (error.response.status === 401) {
        throw new Error('Sessão expirada. Por favor, faça login novamente.');
      }
      throw new Error(error.response.data?.message || defaultMessage);
    } else if (error.request) {
      throw new Error('Erro de conexão. Verifique sua internet.');
    } else {
      throw new Error('Erro inesperado. Tente novamente mais tarde.');
    }
  };

  return {
    fetchProjects,
    fetchProject,
    createProject,
    updateProject,
    deleteProject
  };
};
