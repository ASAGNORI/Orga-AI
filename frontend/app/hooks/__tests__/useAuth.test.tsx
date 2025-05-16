import { renderHook, act } from '@testing-library/react';
import { useAuth } from '../useAuth';
import { AuthProvider } from '../../contexts/AuthContext';
import * as authAdapter from '@/services/auth-adapter';

// Mock Next.js router
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    replace: jest.fn(),
  }),
}));

// Mock auth service
jest.mock('@/services/auth-adapter');

const mockUser = {
  id: '123',
  email: 'test@example.com',
  full_name: 'Test User'
};

describe('useAuth', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (authAdapter.getCurrentUser as jest.Mock).mockResolvedValue({ user: null });
  });

  it('initializes with null user and no error', async () => {
    const { result } = renderHook(() => useAuth(), {
      wrapper: AuthProvider,
    });

    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0));
    });

    expect(result.current.user).toBeNull();
    expect(result.current.error).toBeNull();
    expect(result.current.isLoading).toBe(false);
  });

  it('loads user from localStorage on mount', async () => {
    (authAdapter.getCurrentUser as jest.Mock).mockResolvedValueOnce({ 
      user: mockUser,
      session: { access_token: 'test-token' }
    });

    const { result } = renderHook(() => useAuth(), {
      wrapper: AuthProvider,
    });

    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0));
    });

    expect(result.current.user).toEqual(mockUser);
    expect(result.current.error).toBeNull();
  });

  it('handles login success', async () => {
    (authAdapter.login as jest.Mock).mockResolvedValueOnce({ 
      user: mockUser,
      session: { access_token: 'test-token' }
    });

    const { result } = renderHook(() => useAuth(), {
      wrapper: AuthProvider,
    });

    await act(async () => {
      await result.current.login('test@example.com', 'password');
    });

    expect(result.current.user).toEqual(mockUser);
    expect(result.current.error).toBeNull();
    expect(result.current.isLoading).toBe(false);
  });

  it('handles login error', async () => {
    const error = { message: 'Invalid credentials' };
    (authAdapter.login as jest.Mock).mockRejectedValueOnce(error);

    const { result } = renderHook(() => useAuth(), {
      wrapper: AuthProvider,
    });

    await act(async () => {
      try {
        await result.current.login('test@example.com', 'wrong');
      } catch (e) {
        // Error esperado
      }
    });

    expect(result.current.user).toBeNull();
    expect(result.current.error).toBeTruthy();
    expect(result.current.isLoading).toBe(false);
  });

  it('handles logout', async () => {
    const { result } = renderHook(() => useAuth(), {
      wrapper: AuthProvider,
    });

    await act(async () => {
      await result.current.logout();
    });

    expect(result.current.user).toBeNull();
    expect(result.current.isAuthenticated).toBe(false);
    expect(localStorage.getItem('auth_token')).toBeNull();
  });
});