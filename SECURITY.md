# Política de Segurança

## Versões Suportadas

Atualmente, estamos fornecendo atualizações de segurança para as seguintes versões do Orga.AI:

| Versão | Suporte          |
| ------ | ---------------- |
| 1.x.x  | :white_check_mark: |
| < 1.0  | :x:              |

## Relatando uma Vulnerabilidade

Agradecemos por nos ajudar a manter o Orga.AI seguro. Seguimos as práticas de divulgação responsável:

1. **Como reportar**: Envie uma descrição detalhada da vulnerabilidade para [security@orga-ai.com](mailto:security@orga-ai.com)
2. **O que incluir**:
   - Tipo de problema (ex: buffer overflow, XSS, etc.)
   - Locais completos ou caminhos dos arquivos fonte relacionados ao problema
   - Qualquer requisito especial para reproduzir o problema
   - Passos para reprodução
   - Impacto do problema e quaisquer dados sensíveis em potencial que possam estar expostos

3. **O que esperar**:
   - Acusaremos o recebimento do seu relatório dentro de 48 horas
   - Nossa equipe investigará e manterá você atualizado sobre nosso progresso
   - Se a vulnerabilidade for aceita, trabalharemos em uma correção e coordenaremos a divulgação
   - Seu nome será creditado na seção de agradecimentos de segurança (se desejado)

## Práticas de Segurança

O Orga.AI implementa as seguintes práticas de segurança:

- Autenticação segura via Supabase Auth
- Endpoints da API protegidos com autenticação JWT
- Armazenamento seguro de senhas e tokens
- Proteção contra XSS e CSRF
- Sanitização de entradas de usuários
- Política de CORS configurada apropriadamente
- Modelos de IA executados localmente (Ollama) para privacidade dos dados

## Dependências e Bibliotecas

Regularmente escaneamos e atualizamos nossas dependências para resolver vulnerabilidades conhecidas.
