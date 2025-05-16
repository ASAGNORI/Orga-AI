import React from 'react';
import { render, act } from '@testing-library/react';
import { AuthContext, AuthProvider } from '../AuthContext';

// Mock Next.js router
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    replace: jest.fn(),
  }),
}));

// Mock auth service
jest.mock('@/services/auth-adapter', () => ({
  getCurrentUser: jest.fn().mockResolvedValue({ user: null }),
  login: jest.fn(),
  logout: jest.fn(),
  register: jest.fn(),
}));

describe('AuthContext', () => {
  it('provides default context values', async () => {
    let contextValue: any;
    
    const TestComponent = () => {
      contextValue = React.useContext(AuthContext);
      return null;
    };

    await act(async () => {
      render(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );
    });

    expect(contextValue).toBeDefined();
    expect(contextValue.user).toBeNull();
    expect(contextValue.error).toBeNull();
    // O loading começa como true e muda para false após a verificação inicial
    expect(contextValue.isLoading).toBe(false);
  });
});
