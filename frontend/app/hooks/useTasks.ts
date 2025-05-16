import { useEffect } from 'react';
import { useStore } from '@/store';
import { useTaskService } from '@/services/taskService';

export function useTasks() {
  const tasks = useStore(state => state.tasks);
  const isLoading = useStore(state => state.isLoading);
  const error = useStore(state => state.error);
  const { fetchTasks } = useTaskService();

  useEffect(() => {
    fetchTasks();
  }, []);

  return { tasks, isLoading, error };
}