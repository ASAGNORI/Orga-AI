// Get API URL based on environment
const getApiUrl = () => {
  // In browser, use window.location to determine API URL
  if (typeof window !== 'undefined') {
    const protocol = window.location.protocol;
    const hostname = window.location.hostname;
    const port = '8000'; // Backend always runs on port 8000
    return `${protocol}//${hostname}:${port}`;
  }
  
  // During SSR or build, use environment variable or default
  return process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
};

export const config = {
  apiUrl: getApiUrl(),
  frontendUrl: process.env.NEXT_PUBLIC_FRONTEND_URL || 'http://localhost:3010',
  authTokenKey: 'auth_token',
  sessionKey: 'session',
  publicPaths: ['/login', '/register', '/', '/about', '/public-test'],
};
