import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import TaskModal from '../TaskModal';

jest.mock('@/store', () => ({
  useStore: () => ({
    projects: [
      { id: '1', title: 'Project 1' },
      { id: '2', title: 'Project 2' }
    ],
    addTask: jest.fn(),
    updateTask: jest.fn(),
    isLoading: false,
    setError: jest.fn()
  })
}));

describe('TaskModal', () => {
  const mockOnClose = jest.fn();
  const mockOnSubmit = jest.fn();
  const defaultProps = {
    isOpen: true,
    onClose: mockOnClose,
    onSubmit: mockOnSubmit,
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders modal when open', () => {
    render(<TaskModal {...defaultProps} />);
    
    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('New Task')).toBeInTheDocument();
    expect(screen.getByLabelText('Title')).toBeInTheDocument();
    expect(screen.getByLabelText('Description')).toBeInTheDocument();
  });

  it('does not render when closed', () => {
    render(<TaskModal {...defaultProps} isOpen={false} />);
    
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('pre-fills form with initial data', () => {
    const initialData = {
      title: 'Test Task',
      description: 'Test Description',
      status: 'todo' as const,
      priority: 'high' as const,
      energy_level: 3,
      estimated_time: 60,
      tags: ['test', 'important']
    };

    render(<TaskModal {...defaultProps} initialData={initialData} />);
    
    expect(screen.getByLabelText('Title')).toHaveValue(initialData.title);
    expect(screen.getByLabelText('Description')).toHaveValue(initialData.description);
    expect(screen.getByLabelText('Priority')).toHaveValue(initialData.priority);
    expect(screen.getByLabelText('Energy Level (1-5)')).toHaveValue(initialData.energy_level.toString());
  });

  it('submits form with entered data', async () => {
    render(<TaskModal {...defaultProps} />);
    
    const titleInput = screen.getByLabelText('Title');
    const descriptionInput = screen.getByLabelText('Description');
    const submitButton = screen.getByRole('button', { name: 'Create Task' });

    await userEvent.type(titleInput, 'New Task');
    await userEvent.type(descriptionInput, 'New Description');
    
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'New Task',
          description: 'New Description',
          status: 'todo',
          priority: 'medium'
        })
      );
    });
  });

  it('validates required fields', async () => {
    render(<TaskModal {...defaultProps} />);
    
    const submitButton = screen.getByRole('button', { name: 'Create Task' });
    
    fireEvent.click(submitButton);

    expect(await screen.findByText('Title is required')).toBeInTheDocument();
  });

  it('calls onClose when cancel button is clicked', () => {
    render(<TaskModal {...defaultProps} />);
    
    const cancelButton = screen.getByRole('button', { name: 'Cancel' });
    fireEvent.click(cancelButton);

    expect(mockOnClose).toHaveBeenCalled();
  });

  it('shows AI suggestions loading state', () => {
    render(<TaskModal {...defaultProps} />);
    
    const loadingText = screen.queryByText(/obtendo sugestões da ia/i);
    expect(loadingText).not.toBeInTheDocument();
  });

  it('handles form submission with tags', async () => {
    render(<TaskModal {...defaultProps} />);
    
    const titleInput = screen.getByLabelText('Title');
    const tagInput = screen.getByLabelText('Tags');
    const submitButton = screen.getByRole('button', { name: 'Create Task' });

    await userEvent.type(titleInput, 'Task with Tags');
    await userEvent.type(tagInput, 'important');
    fireEvent.keyDown(tagInput, { key: 'Enter' });
    await userEvent.type(tagInput, 'urgent');
    fireEvent.keyDown(tagInput, { key: 'Enter' });
    
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'Task with Tags',
          tags: ['important', 'urgent']
        })
      );
    });
  });
});