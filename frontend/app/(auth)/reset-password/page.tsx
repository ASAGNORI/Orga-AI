'use client';

import { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { useAuth } from "@/hooks/useAuth";

export default function ResetPasswordPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const token = searchParams.get('token');
  
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const { resetPassword, updatePassword, user } = useAuth();
  
  // Controle de redirecionamento baseado no estado de autenticação
  useEffect(() => {
    if (user) {
      router.replace('/dashboard');
    }
  }, [user, router]);

  // Controle de redirecionamento após sucesso
  useEffect(() => {
    if (success && token) {
      const timer = setTimeout(() => {
        router.push('/login');
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [success, token, router]);

  const handleResetRequest = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (loading) return;

    setLoading(true);
    setError(null);
    
    try {
      await resetPassword(email);
      setSuccess(true);
    } catch (err: any) {
      console.error('Erro ao solicitar redefinição de senha:', err);
      setError(err.message || 'Ocorreu um erro ao processar sua solicitação');
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordUpdate = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (loading) return;

    if (password !== confirmPassword) {
      setError('As senhas não coincidem');
      return;
    }

    setLoading(true);
    setError(null);
    
    try {
      // Validate password requirements
      if (password.length < 8) {
        setError('A senha deve ter pelo menos 8 caracteres');
        return;
      }
      
      // At least one uppercase, one lowercase, one number and one special character
      if (!/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/.test(password)) {
        setError('A senha deve conter pelo menos uma letra maiúscula, uma minúscula, um número e um caractere especial');
        return;
      }

      await updatePassword(token!, password);
      setSuccess(true);
    } catch (err: any) {
      console.error('Erro ao atualizar senha:', err);
      if (err.message.includes('Token expirado')) {
        setError('O link de redefinição expirou. Por favor, solicite um novo link.');
      } else if (err.message.includes('Token inválido')) {
        setError('Link de redefinição inválido. Por favor, verifique o link ou solicite um novo.');
      } else {
        setError(err.message || 'Ocorreu um erro ao atualizar sua senha');
      }
    } finally {
      setLoading(false);
    }
  };

  // Renderiza o formulário de nova senha se houver token
  if (token) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background py-12 px-4 sm:px-6 lg:px-8">
        <Card className="w-full max-w-md">
          <CardHeader className="space-y-1">
            <CardTitle className="text-2xl text-center">Nova Senha</CardTitle>
            <CardDescription className="text-center">
              Digite sua nova senha
            </CardDescription>
          </CardHeader>
          <CardContent>
            {success ? (
              <Alert className="bg-green-50 border-green-500">
                <AlertDescription className="text-green-700">
                  Sua senha foi atualizada com sucesso! Redirecionando para o login...
                </AlertDescription>
              </Alert>
            ) : (
              <form className="space-y-4" onSubmit={handlePasswordUpdate}>
                <div className="space-y-2">
                  <Input
                    id="password"
                    type="password"
                    placeholder="Nova senha"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    disabled={loading}
                    required
                    minLength={6}
                  />
                  <Input
                    id="confirmPassword"
                    type="password"
                    placeholder="Confirme a nova senha"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    disabled={loading}
                    required
                    minLength={6}
                  />
                </div>

                {error && (
                  <Alert variant="destructive">
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}

                <Button
                  type="submit"
                  className="w-full"
                  disabled={loading}
                >
                  {loading ? "Atualizando..." : "Atualizar senha"}
                </Button>
              </form>
            )}
          </CardContent>
        </Card>
      </div>
    );
  }

  // Formulário de solicitação de reset
  return (
    <div className="min-h-screen flex items-center justify-center bg-background py-12 px-4 sm:px-6 lg:px-8">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl text-center">Redefinir Senha</CardTitle>
          <CardDescription className="text-center">
            Insira seu email para receber um link de redefinição de senha
          </CardDescription>
        </CardHeader>
        <CardContent>
          {success ? (
            <div className="space-y-4">
              <Alert className="bg-green-50 border-green-500">
                <AlertDescription className="text-green-700">
                  Se esse email estiver cadastrado em nossa base de dados, você receberá em instantes as instruções para redefinir sua senha.
                </AlertDescription>
              </Alert>
              <Button 
                className="w-full" 
                onClick={() => router.push('/login')}
              >
                Voltar para o Login
              </Button>
            </div>
          ) : (
            <form className="space-y-4" onSubmit={handleResetRequest}>
              <div className="space-y-2">
                <Input
                  id="email"
                  type="email"
                  placeholder="Seu email cadastrado"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                  required
                />
              </div>

              {error && (
                <Alert variant="destructive">
                  <AlertDescription>{error}</AlertDescription>
                </Alert>
              )}

              <Button
                type="submit"
                className="w-full"
                disabled={loading}
              >
                {loading ? "Processando..." : "Enviar link de redefinição"}
              </Button>
            </form>
          )}
        </CardContent>
        <CardFooter className="justify-center">
          <Link
            href="/login"
            className="text-sm text-primary hover:text-primary/90"
          >
            Voltar para o login
          </Link>
        </CardFooter>
      </Card>
    </div>
  );
}