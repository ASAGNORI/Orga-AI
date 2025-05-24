# Instruções Detalhadas para Correção do N8N Email Workflow

## Visão Geral dos Problemas

Identificamos dois problemas principais no workflow de email do N8N:

1. **Falta de substituição de placeholders**: Muitos emails estão sendo enviados com placeholders como `[Nome do Usuário]` e `[Número de tarefas concluídas]` em vez de valores reais.

2. **Geração de conteúdo muito genérico pela IA**: O conteúdo gerado pela IA não está incorporando dados específicos do usuário, resultando em emails genéricos e impessoais.

## Solução Implementada

Criamos dois scripts de processamento para resolver estes problemas:

1. **`prepare_ai_email_prompt.js`**: Prepara um prompt enriquecido para a IA, incluindo dados reais do usuário.
2. **`format_ai_email.js`**: Processa a resposta da IA, substituindo quaisquer placeholders remanescentes com dados reais.

## Passos para Implementação

### 1. Importação dos Scripts para o N8N

1. Faça login no N8N (http://localhost:5678)
2. Acesse o workflow de "Email Diário"
3. Use os seguintes scripts nos nós correspondentes:

### 2. Configuração do Nó de Preparação do Prompt

1. Adicione um nó "Code" antes da chamada à API da IA
2. Configure como:
   - Nome: "Preparar Prompt para IA"
   - Linguagem: JavaScript
   - Execute para: "Todos os itens"
   - Cole o conteúdo do arquivo `prepare_ai_email_prompt.js`
   - A saída deve ser conectada ao nó de API da IA

### 3. Configuração do Nó de Formatação da Resposta

1. Adicione/modifique outro nó "Code" após a resposta da API
2. Configure como:
   - Nome: "Formatar Email"
   - Linguagem: JavaScript
   - Execute para: "Todos os itens"
   - Cole o conteúdo do arquivo `format_ai_email.js`
   - A saída deve ser conectada ao nó de envio de email

### 4. Atualização do Modelo de Prompt

O nó de "Preparar Prompt para IA" gera um prompt detalhado com a seguinte estrutura:

```
Gere um e-mail motivacional personalizado para [Nome Real do Usuário].
A data atual é [Data Formatada].

Informações específicas para incluir:
- Nome do usuário: [Nome Real]
- Total de tarefas: [Valor Real]
- Tarefas concluídas: [Valor Real]
- Tarefas pendentes: [Valor Real]
...
```

### 5. Fluxo Completo do Workflow

O fluxo do workflow deve seguir esta sequência:

1. **Trigger** (acionador) - Executa o workflow em um horário programado
2. **Consulta de Dados** - Obtém dados do usuário e tarefas do banco de dados
3. **Preparação do Prompt** - Executa `prepare_ai_email_prompt.js` para criar o prompt enriquecido
4. **Chamada à API da IA** - Envia o prompt para a API de IA gerar o conteúdo do email
5. **Formatação da Resposta** - Executa `format_ai_email.js` para garantir que todos os placeholders sejam substituídos
6. **Envio do Email** - Envia o email formatado para o usuário

## Verificação da Correção

Para garantir que a solução está funcionando corretamente:

1. Execute o workflow manualmente para um único usuário
2. Verifique o email resultante para garantir que:
   - O nome do usuário aparece corretamente
   - As estatísticas de tarefas são precisas
   - Não há placeholders visíveis no email final
   - O conteúdo é personalizado e relevante para o usuário específico

## Troubleshooting

Se ainda ocorrerem problemas:

1. **Verifique os logs do N8N** para identificar em qual etapa está ocorrendo o problema
2. **Examine o objeto de dados** em cada etapa para garantir que está estruturado corretamente
3. **Teste o script individualmente** com dados de amostra

## Manutenção Futura

A abordagem implementada é robusta e escalável, mas requer manutenção em certas circunstâncias:

- Se a estrutura do banco de dados mudar
- Se novos campos forem adicionados aos usuários ou tarefas
- Se a formatação do email precisar ser atualizada

Mantenha estes scripts atualizados quando houver mudanças significativas na estrutura dos dados ou na lógica de negócios.
