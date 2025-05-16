import api from './api';
import { config as appConfig } from '../config';

interface LoginCredentials {
  email: string;
  password: string;
}

interface RegisterCredentials {
  email: string;
  password: string;
  full_name: string;
}

export interface AuthResponse {
  session?: {
    access_token: string;
    token_type: string;
  };
  error?: {
    status: number;
    message: string;
    details?: any;
  };
  user?: {
    id: number;
    email: string;
    full_name: string;
  };
}

const formatError = (error: any, defaultMessage: string): AuthResponse => ({
  error: {
    status: error.status || 500,
    message: error.message || defaultMessage,
    details: error
  }
});

const getApiUrl = () => {
  return process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';
};

const handleAuthResponse = async (response: Response): Promise<AuthResponse> => {
  const data = await response.json();
  
  if (!response.ok) {
    return formatError(data, 'Erro na requisição');
  }
  
  return {
    session: {
      access_token: data.access_token,
      token_type: data.token_type || 'bearer'
    },
    user: data.user
  };
};

export const login = async (credentials: LoginCredentials): Promise<AuthResponse> => {
  try {
    const response = await fetch(`${getApiUrl()}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({ 
        grant_type: 'password',
        username: credentials.email, 
        password: credentials.password 
      })
    });

    const authResponse = await handleAuthResponse(response);
    
    if (authResponse.session?.access_token) {
      localStorage.setItem('auth_token', authResponse.session.access_token);
      if (authResponse.user) {
        localStorage.setItem('user', JSON.stringify(authResponse.user));
      }
      // Set cookie for middleware auth
      document.cookie = `${appConfig.authTokenKey}=${authResponse.session.access_token}; path=/`;
    }

    return authResponse;
  } catch (error: any) {
    return formatError(error, 'Erro ao fazer login');
  }
};

export const register = async (credentials: RegisterCredentials): Promise<AuthResponse> => {
  try {
    const response = await fetch(`${getApiUrl()}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(credentials)
    });
    
    const authResponse = await handleAuthResponse(response);
    
    if (authResponse.error) {
      return authResponse;
    }

    // After successful registration, login automatically
    return await login({ 
      email: credentials.email, 
      password: credentials.password 
    });
  } catch (error: any) {
    return formatError(error, 'Erro ao criar conta');
  }
};

export const getCurrentUser = async (): Promise<AuthResponse> => {
  try {
    const token = localStorage.getItem('auth_token');
    if (!token) {
      return {
        error: {
          status: 401,
          message: 'Não autenticado'
        }
      };
    }

    // Try to get cached user first
    const cachedUser = localStorage.getItem('user');
    if (cachedUser) {
      return {
        user: JSON.parse(cachedUser),
        session: { access_token: token, token_type: 'bearer' }
      };
    }

    const response = await fetch(`${getApiUrl()}/auth/me`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    if (!response.ok) {
      if (response.status === 401) {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user');
      }
      const data = await response.json();
      return formatError(data, 'Sessão expirada');
    }

    const userData = await response.json();
    const user = {
      id: userData.id,
      email: userData.email,
      full_name: userData.full_name
    };
    
    // Cache user data
    localStorage.setItem('user', JSON.stringify(user));
    
    return {
      user,
      session: { access_token: token, token_type: 'bearer' }
    };
  } catch (error: any) {
    return formatError(error, 'Erro ao verificar autenticação');
  }
};

export const logout = async (): Promise<void> => {
  localStorage.removeItem('auth_token');
  localStorage.removeItem('user');
  // Remove auth token cookie
  document.cookie = `${appConfig.authTokenKey}=; Max-Age=0; path=/`;
};