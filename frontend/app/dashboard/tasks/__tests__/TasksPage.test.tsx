import { render, screen } from '@testing-library/react'
import { useStore } from '@/store'
import TasksPage from '../page'

// Mock the store
jest.mock('@/store')

interface Task {
  id: string;
  title: string;
  status: 'todo' | 'in_progress' | 'done';
}

// Helper type for mocking store
type MockStore = {
  tasks: Task[];
  isLoading: boolean;
  error: string | null;
  fetchTasks: jest.Mock;
  addTask: jest.Mock;
  updateTask: jest.Mock;
  deleteTask: jest.Mock;
}

describe('TasksPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders loading states initially', () => {
    const mockStore: MockStore = {
      tasks: [],
      isLoading: true,
      error: null,
      fetchTasks: jest.fn(),
      addTask: jest.fn(),
      updateTask: jest.fn(),
      deleteTask: jest.fn()
    }
    
    ;(useStore as jest.MockedFunction<typeof useStore>).mockImplementation(() => mockStore)

    render(<TasksPage />)
    const loadingSpinners = screen.getAllByRole('status')
    expect(loadingSpinners).toHaveLength(3)
  })

  it('renders tasks when loaded', () => {
    const mockTasks: Task[] = [
      { id: '1', title: 'Task 1', status: 'todo' },
      { id: '2', title: 'Task 2', status: 'in_progress' },
      { id: '3', title: 'Task 3', status: 'done' }
    ]

    const mockStore: MockStore = {
      tasks: mockTasks,
      isLoading: false,
      error: null,
      fetchTasks: jest.fn(),
      addTask: jest.fn(),
      updateTask: jest.fn(),
      deleteTask: jest.fn()
    }

    ;(useStore as jest.MockedFunction<typeof useStore>).mockImplementation(() => mockStore)

    render(<TasksPage />)

    expect(screen.getByText('Task 1')).toBeInTheDocument()
    expect(screen.getByText('Task 2')).toBeInTheDocument()
    expect(screen.getByText('Task 3')).toBeInTheDocument()
  })

  it('shows error message when loading fails', () => {
    const mockStore: MockStore = {
      tasks: [],
      isLoading: false,
      error: 'Failed to load tasks',
      fetchTasks: jest.fn(),
      addTask: jest.fn(),
      updateTask: jest.fn(),
      deleteTask: jest.fn()
    }

    ;(useStore as jest.MockedFunction<typeof useStore>).mockImplementation(() => mockStore)

    render(<TasksPage />)

    expect(screen.getByText(/Failed to load tasks/i)).toBeInTheDocument()
  })
})