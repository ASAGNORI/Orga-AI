import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Loader2, ExternalLink } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useToast } from '@/hooks/use-toast'; // Caminho corrigido para o hook useToast

/**
 * Botão para acessar o Open WebUI via SSO
 * Faz requisição para o endpoint de SSO e redireciona o usuário
 */
export default function WebUIButton() {
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const { toast } = useToast();

  const handleAccessOpenWebUI = async () => {
    try {
      setLoading(true);
      
      // Chamada para o endpoint de SSO
      const response = await fetch('/api/v1/webui/sso', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Importante para enviar cookies de autenticação
      });

      const data = await response.json();
      
      if (!response.ok || !data.success) {
        throw new Error(data.message || 'Erro ao gerar token SSO');
      }

      // Determinar a URL base do Open WebUI
      const openWebUIUrl = process.env.NEXT_PUBLIC_OPENWEBUI_URL || 'http://localhost:3000';
      
      // Redirecionar para o Open WebUI com o token obtido
      // Usamos window.open para abrir em uma nova aba
      window.open(`${openWebUIUrl}/sso?token=${data.token.access_token}`, '_blank');
    } catch (error) {
      console.error("Erro ao acessar Open WebUI:", error);
      toast({
        title: 'Erro ao acessar Open WebUI',
        description: error instanceof Error ? error.message : 'Ocorreu um erro desconhecido',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button
      onClick={handleAccessOpenWebUI}
      disabled={loading}
      variant="outline"
      className="flex gap-2 items-center"
    >
      {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <ExternalLink className="h-4 w-4" />}
      Acessar Open WebUI
    </Button>
  );
}