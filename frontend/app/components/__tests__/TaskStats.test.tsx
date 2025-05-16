import { render, screen } from '@testing-library/react';
import TaskStats from '../TaskStats';

jest.mock('@/store', () => ({
  useStore: () => ({
    taskStats: {
      total: 10,
      completed: 5,
      overdue: 2,
      dueToday: 3,
      dueThisWeek: 7,
      byPriority: {
        high: 3,
        medium: 4,
        low: 3
      },
      byTag: {
        work: 4,
        personal: 3,
        urgent: 3
      }
    },
    isLoading: false,
    fetchTaskStats: jest.fn()
  })
}));

describe('TaskStats', () => {
  it('renders task statistics correctly', () => {
    render(<TaskStats />);
    
    expect(screen.getByText('10')).toBeInTheDocument(); // total
    expect(screen.getByText('50%')).toBeInTheDocument(); // completion rate
    expect(screen.getByText('2')).toBeInTheDocument(); // overdue
    expect(screen.getByText('3')).toBeInTheDocument(); // due today
  });

  it('renders priority distribution', () => {
    render(<TaskStats />);
    
    expect(screen.getByText('3')).toBeInTheDocument(); // high priority
    expect(screen.getByText('4')).toBeInTheDocument(); // medium priority
    expect(screen.getByText('3')).toBeInTheDocument(); // low priority
  });

  it('renders tag distribution', () => {
    render(<TaskStats />);
    
    expect(screen.getByText('work (4)')).toBeInTheDocument();
    expect(screen.getByText('personal (3)')).toBeInTheDocument();
    expect(screen.getByText('urgent (3)')).toBeInTheDocument();
  });
});