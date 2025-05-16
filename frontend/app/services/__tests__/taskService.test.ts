import { createTaskService } from '../taskService';
import api from '../api';

jest.mock('../api');

describe('TaskService', () => {
  const mockDeps = {
    setTasks: jest.fn(),
    addTask: jest.fn(),
    updateTask: jest.fn(),
    deleteTask: jest.fn(),
    setIsLoading: jest.fn(),
    setError: jest.fn(),
  };

  const taskService = createTaskService(mockDeps);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('fetchTasks', () => {
    it('fetches tasks successfully', async () => {
      const mockTasks = [
        { id: '1', title: 'Task 1', status: 'todo', priority: 'medium' },
        { id: '2', title: 'Task 2', status: 'in_progress', priority: 'high' }
      ];

      (api.get as jest.Mock).mockResolvedValueOnce({ data: mockTasks });

      await taskService.fetchTasks();

      expect(mockDeps.setIsLoading).toHaveBeenCalledWith(true);
      expect(mockDeps.setTasks).toHaveBeenCalledWith(mockTasks);
      expect(mockDeps.setIsLoading).toHaveBeenCalledWith(false);
    });

    it('handles fetch tasks error', async () => {
      const error = new Error('Failed to fetch tasks');
      (api.get as jest.Mock).mockRejectedValueOnce(error);

      await taskService.fetchTasks();

      expect(mockDeps.setError).toHaveBeenCalled();
      expect(mockDeps.setIsLoading).toHaveBeenCalledWith(false);
    });
  });

  describe('createTask', () => {
    it('creates task successfully', async () => {
      const newTask = {
        title: 'New Task',
        status: 'todo' as const,
        priority: 'medium' as const
      };
      const createdTask = { ...newTask, id: '3' };

      (api.post as jest.Mock).mockResolvedValueOnce({ data: createdTask });

      const result = await taskService.createTask(newTask);

      expect(mockDeps.setIsLoading).toHaveBeenCalledWith(true);
      expect(mockDeps.addTask).toHaveBeenCalledWith(createdTask);
      expect(result).toEqual(createdTask);
    });

    it('handles create task error', async () => {
      const newTask = {
        title: 'New Task',
        status: 'todo' as const,
        priority: 'medium' as const
      };
      const error = new Error('Failed to create task');
      (api.post as jest.Mock).mockRejectedValueOnce(error);

      const result = await taskService.createTask(newTask);

      expect(mockDeps.setError).toHaveBeenCalled();
      expect(result).toBeNull();
    });
  });

  describe('updateTask', () => {
    it('updates task successfully', async () => {
      const taskId = '1';
      const updates = { title: 'Updated Task' };
      const updatedTask = { id: taskId, ...updates };

      (api.put as jest.Mock).mockResolvedValueOnce({ data: updatedTask });

      const result = await taskService.updateTask(taskId, updates);

      expect(mockDeps.setIsLoading).toHaveBeenCalledWith(true);
      expect(mockDeps.updateTask).toHaveBeenCalledWith(taskId, updatedTask);
      expect(result).toEqual(updatedTask);
    });

    it('handles update task error', async () => {
      const taskId = '1';
      const updates = { title: 'Updated Task' };
      const error = new Error('Failed to update task');
      (api.put as jest.Mock).mockRejectedValueOnce(error);

      const result = await taskService.updateTask(taskId, updates);

      expect(mockDeps.setError).toHaveBeenCalled();
      expect(result).toBeNull();
    });
  });

  describe('deleteTask', () => {
    it('deletes task successfully', async () => {
      const taskId = '1';
      (api.delete as jest.Mock).mockResolvedValueOnce({});

      const result = await taskService.deleteTask(taskId);

      expect(mockDeps.setIsLoading).toHaveBeenCalledWith(true);
      expect(mockDeps.deleteTask).toHaveBeenCalledWith(taskId);
      expect(result).toBe(true);
    });

    it('handles delete task error', async () => {
      const taskId = '1';
      const error = new Error('Failed to delete task');
      (api.delete as jest.Mock).mockRejectedValueOnce(error);

      const result = await taskService.deleteTask(taskId);

      expect(mockDeps.setError).toHaveBeenCalled();
      expect(result).toBe(false);
    });
  });
});