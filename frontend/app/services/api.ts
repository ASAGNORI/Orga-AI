import axios from 'axios';
import { config } from '../config';

export const API_URL = config.apiUrl;

const api = axios.create({
  baseURL: config.apiUrl,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  withCredentials: true, // Enable cookies for CORS
  timeout: 15000 // Increased timeout for better reliability
});

// Interceptor para adicionar token de autenticação
api.interceptors.request.use(
  (config) => {
    // Tenta obter o token do localStorage
    let token = localStorage.getItem('auth_token');
    
    // Se não encontrar no localStorage, tenta no sessionStorage
    if (!token) {
      token = sessionStorage.getItem('auth_token');
    }
    
    if (token) {
      config.headers = {
        ...config.headers,
        Authorization: `Bearer ${token}`
      };
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Interceptor para tratamento de erros
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (!error.response) {
      // Network or timeout error
      console.error('Network Error:', error.message);
      throw new Error('Connection error. Please check your internet connection and try again.');
    }

    // Handle specific error status codes
    if (error.response.status === 404) {
      throw new Error('Resource not found');
    }
    if (error.response.status === 403) {
      throw new Error('Access denied');
    }
    if (error.response.status >= 500) {
      throw new Error('Server error. Please try again later.');
    }
 
    const originalRequest = error.config;

    // Handle 401 (Unauthorized) error and token refresh
    if (error.response.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        // Try to refresh the token
        const refreshResponse = await fetch(`${config.apiUrl}/auth/refresh`, {
          method: 'POST',
          credentials: 'include',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
        });

        if (refreshResponse.ok) {
          const { access_token, refresh_token } = await refreshResponse.json();
          
          // Update tokens in storage
          localStorage.setItem('auth_token', access_token);
          if (refresh_token) {
            localStorage.setItem('refresh_token', refresh_token);
          }
          
          // Update request authorization header
          if (originalRequest.headers) {
            originalRequest.headers['Authorization'] = `Bearer ${access_token}`;
          }
          
          return api(originalRequest);
        } else {
          // If refresh fails, redirect to login
          throw new Error('Session expired. Please login again.');
        }
      } catch (refreshError) {
        console.error('Error refreshing token:', refreshError);
        // Se falhar o refresh, limpa os tokens e redireciona para login
        localStorage.removeItem('auth_token');
        sessionStorage.removeItem('auth_token');
        if (typeof window !== 'undefined') {
          window.location.href = '/login';
        }
      }
    }

    // Se não for erro de autenticação ou o refresh falhar, rejeita com o erro original
    return Promise.reject(error);
  }
);

export default api;