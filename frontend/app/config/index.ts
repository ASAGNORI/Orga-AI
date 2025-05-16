// Função para detectar o ambiente e usar a URL apropriada
const getApiUrl = () => {
  // Use a variável de ambiente se estiver disponível
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  
  // Em ambiente de navegador, use o IP/host atual para a API
  if (typeof window !== 'undefined') {
    const protocol = window.location.protocol;
    const host = window.location.hostname;
    const isLocalhost = host === 'localhost' || host === '127.0.0.1';
    const apiPort = process.env.NEXT_PUBLIC_API_PORT || '8000';
    // Se estiver em desenvolvimento local, use localhost
    if (isLocalhost) {
      return `http://localhost:${apiPort}`;
    }
    // Em outros ambientes, use o mesmo protocolo e host da aplicação
    return `${protocol}//${host}:${apiPort}`;
  }
  
  // Fallback para localhost durante SSR
  return 'http://localhost:8000';
};

export const config = {
  apiUrl: getApiUrl(),
  authTokenKey: 'auth_token',
  sessionKey: 'session',
  publicPaths: ['/login', '/register', '/', '/about'],
};