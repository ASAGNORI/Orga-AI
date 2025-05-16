'use client';

import { useState } from 'react';
import WebUI from '../../components/WebUI';

export default function WebUIPage() {
  const [showDirectLink, setShowDirectLink] = useState(false);
  const webUiUrl = process.env.NEXT_PUBLIC_OLLAMA_WEBUI_URL || 'http://localhost:3000';

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        
        {showDirectLink && (
          <a 
            href={webUiUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
          >
            Acessar diretamente
          </a>
        )}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow h-[calc(100vh-180px)] min-h-[600px]">
        <WebUI />
      </div>
      
      <div className="mt-4 text-sm text-gray-500 flex justify-center">
        <button 
          onClick={() => setShowDirectLink(!showDirectLink)}
          className="text-indigo-500 hover:underline"
        >
          {showDirectLink ? 'Esconder link direto' : 'Problemas para carregar? Clique aqui'}
        </button>
      </div>
    </div>
  );
}