'use client';

import { useState } from 'react';
import { authService } from '../services/authService';

export default function AuthTest() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [toastMessage, setToastMessage] = useState<{
    title: string;
    description?: string;
    status: 'success' | 'error';
    visible: boolean;
  } | null>(null);

  const showToast = (title: string, description: string | undefined, status: 'success' | 'error') => {
    setToastMessage({ title, description, status, visible: true });
    setTimeout(() => {
      setToastMessage(null);
    }, 5000);
  };

  const handleSignUp = async (): Promise<void> => {
    try {
      setLoading(true);
      const { user } = await authService.signUp(email, password);
      showToast(
        'Conta criada com sucesso!',
        `Verifique seu email: ${user?.email}`,
        'success'
      );
    } catch (error: any) {
      const message = error instanceof Error ? error.message : 'Erro desconhecido';
      showToast('Erro ao criar conta', message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSignIn = async (): Promise<void> => {
    try {
      setLoading(true);
      const { user } = await authService.signIn(email, password);
      showToast(
        'Login realizado com sucesso!',
        `Bem-vindo, ${user?.email}`,
        'success'
      );
    } catch (error: any) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      showToast('Erro ao fazer login', errorMessage, 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async (): Promise<void> => {
    try {
      setLoading(true);
      await authService.signOut();
      showToast('Logout realizado com sucesso!', undefined, 'success');
    } catch (error: any) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      showToast('Erro ao fazer logout', errorMessage, 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-4 max-w-md mx-auto">
      <div className="flex flex-col space-y-4">
        <h2 className="text-xl font-bold">
          Teste de Autenticação
        </h2>
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
        />
        <input
          type="password"
          placeholder="Senha"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
        />
        <button
          className="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
          onClick={handleSignUp}
          disabled={loading}
        >
          {loading ? 'Processando...' : 'Criar Conta'}
        </button>
        <button
          className="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
          onClick={handleSignIn}
          disabled={loading}
        >
          {loading ? 'Processando...' : 'Entrar'}
        </button>
        <button
          className="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
          onClick={handleSignOut}
          disabled={loading}
        >
          {loading ? 'Processando...' : 'Sair'}
        </button>
      </div>

      {toastMessage && toastMessage.visible && (
        <div className={`fixed top-4 right-4 p-4 rounded-md shadow-lg max-w-xs ${
          toastMessage.status === 'success' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'
        }`}>
          <div className="flex">
            <div className="flex-shrink-0">
              {toastMessage.status === 'success' ? (
                <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              ) : (
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              )}
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium">{toastMessage.title}</h3>
              {toastMessage.description && (
                <div className="mt-2 text-sm">
                  <p>{toastMessage.description}</p>
                </div>
              )}
            </div>
            <div className="ml-auto pl-3">
              <div className="-mx-1.5 -my-1.5">
                <button
                  type="button"
                  className={`inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2 ${
                    toastMessage.status === 'success' ? 'text-green-500 hover:bg-green-100 focus:ring-green-600' : 'text-red-500 hover:bg-red-100 focus:ring-red-600'
                  }`}
                  onClick={() => setToastMessage(null)}
                >
                  <span className="sr-only">Dismiss</span>
                  <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}