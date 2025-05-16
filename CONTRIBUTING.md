# CONTRIBUTING.md

# Contribuindo para Orga.AI

Obrigado pelo seu interesse em contribuir com o projeto Orga.AI! Este documento fornece diretrizes e instruções para contribuir efetivamente com nosso projeto.

## Fluxo de trabalho

1. **Fork o repositório**
2. **Clone seu fork**:
   ```bash
   git clone https://github.com/seu-usuario/orga-ai.git
   cd orga-ai
   ```
3. **Configure o ambiente de desenvolvimento**:
   ```bash
   # Para o frontend
   cd frontend
   npm install
   
   # Para o backend
   cd backend
   python -m venv .venv
   source .venv/bin/activate  # ou .venv\Scripts\activate no Windows
   pip install -r requirements.txt
   ```
4. **Crie uma branch para sua feature**:
   ```bash
   git checkout -b feature/nova-funcionalidade
   ```
5. **Faça suas alterações seguindo os padrões de código**
6. **Teste suas alterações**:
   ```bash
   # Frontend
   cd frontend
   npm run lint
   npm run test
   
   # Backend
   cd backend
   pytest
   ```
7. **Commit suas alterações**:
   ```bash
   git commit -m "Implementação: descrição concisa da alteração"
   ```
8. **Push para o GitHub**:
   ```bash
   git push origin feature/nova-funcionalidade
   ```
9. **Abra um Pull Request** descrevendo suas alterações

## Padrões de Código

### Frontend
- **Componentes**: Use componentes funcionais com hooks
- **Gerenciamento de estado**: Zustand para estado global, useState para estado local
- **Formulários**: React Hook Form para validação e gerenciamento
- **Estilos**: TailwindCSS para estilização, preferindo classes utilitárias
- **TypeScript**: Use tipagem adequada para todas as funções e componentes

### Backend
- **API**: Rotas organizadas por domínio em app/routers/
- **Serviços**: Lógica de negócio encapsulada em arquivos de serviço
- **Modelos**: Use SQLAlchemy para definição de tabelas
- **Validação**: Use Pydantic para validação de dados
- **Testes**: pytest para testes unitários e de integração

## Diretrizes para Pull Requests

- **Mantenha os PRs focados** em uma única funcionalidade ou correção
- **Atualize a documentação** relevante
- **Adicione testes** para novas funcionalidades
- **Siga as convenções de commit** do projeto
- **Atualize o CHANGELOG.md** para alterações significativas

## Relatando Bugs

Ao relatar bugs, inclua:
- **Descrição clara** do problema
- **Passos para reprodução**
- **Comportamento esperado** vs. observado
- **Screenshots** quando relevante
- **Informações de ambiente** (navegador, SO, versão)

## Sugestões de Funcionalidades

Adoramos novas ideias! Ao sugerir funcionalidades:
- **Descreva o problema** que a funcionalidade resolve
- **Explique a solução** que você gostaria
- **Considere o impacto** na base de código existente

## Processo de Revisão de Código

Todos os PRs passam por:
1. **Verificação automatizada** (linting, testes)
2. **Revisão de código** por pelo menos um mantenedor
3. **Aprovação final** antes do merge

## Setup de Desenvolvimento com Docker

Para ambiente completo usando Docker:
```bash
# Clonar repositório
git clone https://github.com/seu-usuario/orga-ai.git
cd orga-ai

# Configurar variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env conforme necessário

# Iniciar todos os serviços
./scripts/sh/start.sh

# Para apenas frontend ou backend
./scripts/sh/start.sh --frontend-only
./scripts/sh/start.sh --backend-only
```

## Contato

Para dúvidas sobre contribuições:
- Abra uma issue com a tag "question"
- Entre em contato via [dev@orga-ai.com](mailto:dev@orga-ai.com)

---

Agradecemos antecipadamente por suas contribuições!
