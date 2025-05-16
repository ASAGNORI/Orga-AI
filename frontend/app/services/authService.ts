import { config } from '../config';

// Interface para os dados do usuário
interface User {
  id: string;
  email: string;
  full_name: string;
}

// Interface para a sessão
interface Session {
  access_token: string;
  token_type: string;
}

export const authService = {
  async signUp(email: string, password: string, full_name: string) {
    const response = await fetch(`${config.apiUrl}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password, full_name }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Erro ao criar conta');
    }

    const data = await response.json();
    return { user: data as User, session: null };
  },

  async signIn(email: string, password: string) {
    const response = await fetch(`${config.apiUrl}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'password',
        username: email,
        password: password,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Credenciais inválidas');
    }

    const data = await response.json();
    const token = data.access_token;
    localStorage.setItem(config.authTokenKey, token);
    
    return {
      session: {
        access_token: token,
        token_type: data.token_type,
      } as Session
    };
  },

  async signOut() {
    localStorage.removeItem(config.authTokenKey);
    localStorage.removeItem(config.sessionKey);
  },

  async getCurrentUser(): Promise<User> {
    const token = localStorage.getItem(config.authTokenKey);
    if (!token) {
      throw new Error('Não autenticado');
    }

    const response = await fetch(`${config.apiUrl}/auth/me`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    if (!response.ok) {
      localStorage.removeItem(config.authTokenKey);
      throw new Error('Sessão expirada');
    }

    return await response.json();
  },

  async getSession(): Promise<Session | null> {
    const token = localStorage.getItem(config.authTokenKey);
    if (!token) {
      return null;
    }
    return {
      access_token: token,
      token_type: 'bearer'
    };
  },

  async resetPassword(email: string): Promise<void> {
    const response = await fetch(`${config.apiUrl}/auth/reset-password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Erro ao solicitar redefinição de senha');
    }
  },

  // Simplified auth state change handler
  onAuthStateChange(callback: (event: any, session: any) => void) {
    const unsubscribe = () => {};
    return {
      data: { subscription: { unsubscribe } },
      error: null
    };
  }
};