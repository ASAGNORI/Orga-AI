'use client';

import { useEffect, useRef, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';

// Usar uma abordagem alternativa para evitar problemas de CORS/iframe
const WEBUI_URL = process.env.NEXT_PUBLIC_OLLAMA_WEBUI_URL || 'http://localhost:3000';
const WEBUI_SSO_URL = process.env.NEXT_PUBLIC_BACKEND_API_URL ? `${process.env.NEXT_PUBLIC_BACKEND_API_URL}/webui/sso` : 'http://localhost:8000/api/webui/sso';

export default function WebUI() {
  const { user, getToken } = useAuth();
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const [error, setError] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  const [redirectUrl, setRedirectUrl] = useState<string>(WEBUI_URL);

  useEffect(() => {
    const initializeSSO = async () => {
      try {
        console.log('Iniciando autenticação SSO para WebUI');
        console.log('URL SSO:', WEBUI_SSO_URL);
        
        const token = await getToken();
        if (!token) {
          setError('Você precisa estar autenticado para acessar o WebUI');
          return;
        }

        console.log('Token obtido, fazendo requisição SSO');
        
        // Fazer requisição SSO para o backend
        const response = await fetch(WEBUI_SSO_URL, {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });

        console.log('Resposta da requisição SSO:', response.status);
        const data = await response.json();
        console.log('Dados da resposta SSO:', data);
        
        if (!data.success) {
          setError(data.message || 'Erro ao autenticar no WebUI');
          return;
        }

        // Se temos um URL de redirecionamento, usar ele
        if (data.url) {
          const fullUrl = `${WEBUI_URL}${data.url}`;
          console.log('URL de redirecionamento completa:', fullUrl);
          setRedirectUrl(fullUrl);
          
          // Atualizar o iframe com um pequeno delay para garantir que o estado seja atualizado
          setTimeout(() => {
            if (iframeRef.current) {
              iframeRef.current.src = fullUrl;
            }
          }, 100);
        } else {
          // Se não temos URL de redirecionamento, tentar carregar a página principal
          console.log('Nenhum URL de redirecionamento fornecido, carregando página principal:', WEBUI_URL);
          setRedirectUrl(WEBUI_URL);
        }

      } catch (e) {
        console.error('Erro ao inicializar SSO:', e);
        setError(`Erro ao conectar ao serviço WebUI: ${e instanceof Error ? e.message : 'Erro desconhecido'}`);
        
        // Tenta carregar o WebUI diretamente em caso de erro
        console.log('Tentando carregar WebUI diretamente após erro:', WEBUI_URL);
        setRedirectUrl(WEBUI_URL);
      }
    };

    if (user) {
      initializeSSO();
    }
  }, [user, getToken]);

  const handleIframeLoad = () => {
    setIsLoading(false);
  };

  return (
    <div className="h-full w-full flex flex-col">
      {error ? (
        <div className="flex flex-col gap-4">
          <div className="p-4 bg-red-50 border border-red-200 rounded-md">
            <h3 className="text-lg font-medium text-red-600 mb-2">Erro ao carregar WebUI</h3>
            <p className="text-red-500">{error}</p>
            <div className="mt-4 flex gap-2">
              <button 
                className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
                onClick={() => window.location.reload()}
              >
                Tentar novamente
              </button>
              <a 
                href={WEBUI_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700"
              >
                Abrir em nova aba
              </a>
            </div>
          </div>
          <div className="text-center text-gray-600">
            <p>Se o problema persistir, você pode acessar o WebUI diretamente <a 
              href={WEBUI_URL} 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-indigo-600 hover:underline"
            >clicando aqui</a>.</p>
          </div>
        </div>
      ) : (
        <>
          {isLoading && (
            <div className="flex flex-col justify-center items-center p-8 gap-4">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
              <p className="text-gray-600">Conectando ao Ollama WebUI...</p>
            </div>
          )}
          <div className="flex flex-col gap-2 mb-4">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-semibold">Ollama WebUI</h2>
              <a 
                href={redirectUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm px-2 py-1 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded"
              >
                Abrir em nova janela
              </a>
            </div>
          </div>
          <iframe
            ref={iframeRef}
            src={redirectUrl}
            className="flex-1 w-full h-full min-h-[800px] border rounded"
            onLoad={handleIframeLoad}
            style={{ visibility: isLoading ? 'hidden' : 'visible' }}
            allow="clipboard-read; clipboard-write; camera; microphone"
            sandbox="allow-same-origin allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox allow-downloads allow-modals allow-top-navigation"
          />
        </>
      )}
    </div>
  );
}