const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

interface LoginCredentials {
  email: string;
  password: string;
}

interface RegisterCredentials extends LoginCredentials {
  full_name: string; // Alterado de name para full_name
}

interface AuthResponse {
  user: {
    id: string;
    email: string;
    full_name: string; // Alterado de name para full_name
  } | null;
  session: {
    access_token: string;
    refresh_token: string;
  } | null;
  error?: {
    message: string;
  };
}

export async function login(credentials: LoginCredentials): Promise<AuthResponse> {
  const response = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'password', username: credentials.email, password: credentials.password })
  });
  const data = await response.json();
  if (!response.ok) {
    return { user: null, session: null, error: data };
  }
  return {
    user: {
      id: data.user.id,
      email: data.user.email,
      full_name: data.user.user_metadata?.full_name // Alterado de name para full_name
    },
    session: {
      access_token: data.access_token,
      refresh_token: data.refresh_token
    }
  };
}

export async function register(
  credentials: RegisterCredentials
): Promise<AuthResponse> {
  const response = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: credentials.email,
      password: credentials.password,
      full_name: credentials.full_name // Alterado de name para full_name
    })
  });
  const data = await response.json();
  if (!response.ok) {
    return { user: null, session: null, error: data };
  }
  return {
    user: {
      id: data.user.id,
      email: data.user.email,
      full_name: data.user.user_metadata?.full_name // Alterado de name para full_name
    },
    session: {
      access_token: data.access_token,
      refresh_token: data.refresh_token
    }
  };
}

export async function logout(): Promise<void> {
  await fetch(`${BASE_URL}/auth/v1/logout`, {
    method: 'POST'
  });
}