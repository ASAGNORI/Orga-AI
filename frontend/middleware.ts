import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { config as appConfig } from "./app/config";

export async function middleware(request: NextRequest) {
  const token = request.cookies.get(appConfig.authTokenKey);
  const path = request.nextUrl.pathname;

  // Permitir acesso a rotas públicas
  if (appConfig.publicPaths.includes(path)) {
    return NextResponse.next();
  }

  // Redirecionar para login se não houver token
  if (!token) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('redirect', path);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};