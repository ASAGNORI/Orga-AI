import { authService } from '../authService';

const mockLocalStorage = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn()
};

describe('Auth Service', () => {
  beforeEach(() => {
    Object.defineProperty(window, 'localStorage', {
      value: mockLocalStorage
    });
    jest.clearAllMocks();
  });

  describe('signIn', () => {
    it('stores token and returns session on successful login', async () => {
      const mockResponse = {
        access_token: 'test-token',
        token_type: 'bearer'
      };

      global.fetch = jest.fn().mockImplementationOnce(() => 
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve(mockResponse)
        })
      );

      const result = await authService.signIn('test@example.com', 'password');

      expect(mockLocalStorage.setItem).toHaveBeenCalledWith('auth_token', 'test-token');
      expect(result.session).toEqual({
        access_token: 'test-token',
        token_type: 'bearer'
      });
    });

    it('throws error on failed login', async () => {
      const mockError = { message: 'Invalid credentials' };

      global.fetch = jest.fn().mockImplementationOnce(() => 
        Promise.resolve({
          ok: false,
          json: () => Promise.resolve(mockError)
        })
      );

      await expect(authService.signIn('test@example.com', 'wrong'))
        .rejects.toThrow('Invalid credentials');
    });
  });

  describe('signUp', () => {
    it('returns user data on successful registration', async () => {
      const mockResponse = {
        id: '123',
        email: 'test@example.com',
        full_name: 'Test User'
      };

      global.fetch = jest.fn().mockImplementationOnce(() => 
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve(mockResponse)
        })
      );

      const result = await authService.signUp('test@example.com', 'password', 'Test User');

      expect(result.user).toEqual(mockResponse);
      expect(result.session).toBeNull();
    });

    it('throws error on failed registration', async () => {
      const mockError = { message: 'Email already exists' };

      global.fetch = jest.fn().mockImplementationOnce(() => 
        Promise.resolve({
          ok: false,
          json: () => Promise.resolve(mockError)
        })
      );

      await expect(authService.signUp('test@example.com', 'password', 'Test User'))
        .rejects.toThrow('Email already exists');
    });
  });

  describe('signOut', () => {
    it('removes auth data from localStorage', async () => {
      await authService.signOut();

      expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('auth_token');
      expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('session');
    });
  });

  describe('getCurrentUser', () => {
    it('returns user data when authenticated', async () => {
      const mockUser = {
        id: '123',
        email: 'test@example.com',
        full_name: 'Test User'
      };

      mockLocalStorage.getItem.mockReturnValue('test-token');
      global.fetch = jest.fn().mockImplementationOnce(() => 
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve(mockUser)
        })
      );

      const user = await authService.getCurrentUser();

      expect(user).toEqual(mockUser);
    });

    it('throws error when not authenticated', async () => {
      mockLocalStorage.getItem.mockReturnValue(null);

      await expect(authService.getCurrentUser())
        .rejects.toThrow('Não autenticado');
    });

    it('throws error and clears token on expired session', async () => {
      mockLocalStorage.getItem.mockReturnValue('expired-token');
      global.fetch = jest.fn().mockImplementationOnce(() => 
        Promise.resolve({
          ok: false,
          status: 401
        })
      );

      await expect(authService.getCurrentUser())
        .rejects.toThrow('Sessão expirada');
      expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('auth_token');
    });
  });

  describe('getSession', () => {
    it('returns session when token exists', async () => {
      mockLocalStorage.getItem.mockReturnValue('test-token');

      const session = await authService.getSession();

      expect(session).toEqual({
        access_token: 'test-token',
        token_type: 'bearer'
      });
    });

    it('returns null when no token exists', async () => {
      mockLocalStorage.getItem.mockReturnValue(null);

      const session = await authService.getSession();

      expect(session).toBeNull();
    });
  });
});