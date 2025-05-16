import { render, screen } from '@testing-library/react';
import Kanban from '../Kanban';

// Mock DragDropContext provider
jest.mock('react-beautiful-dnd', () => ({
  DragDropContext: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  Droppable: ({ children }: { children: (provided: any) => React.ReactNode }) => children({
    droppableProps: {},
    innerRef: null,
  }),
  Draggable: ({ children }: { children: (provided: any) => React.ReactNode }) => children({
    draggableProps: {},
    dragHandleProps: {},
    innerRef: null,
  }),
}));

jest.mock('@/store', () => ({
  useStore: () => ({
    tasks: [
      { id: '1', title: 'Task 1', status: 'todo', priority: 'high' },
      { id: '2', title: 'Task 2', status: 'in_progress', priority: 'medium' },
      { id: '3', title: 'Task 3', status: 'done', priority: 'low' }
    ],
    updateTask: jest.fn()
  })
}));

describe('Kanban', () => {
  it('renders kanban board columns', () => {
    render(<Kanban />);
    
    expect(screen.getByText('To Do')).toBeInTheDocument();
    expect(screen.getByText('In Progress')).toBeInTheDocument();
    expect(screen.getByText('Done')).toBeInTheDocument();
  });

  it('displays tasks in correct columns', () => {
    render(<Kanban />);
    
    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.getByText('Task 2')).toBeInTheDocument();
    expect(screen.getByText('Task 3')).toBeInTheDocument();
  });
});