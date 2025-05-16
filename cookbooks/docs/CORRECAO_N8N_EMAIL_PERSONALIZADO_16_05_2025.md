# Correção do Workflow de E-mail no n8n - Inclusão de Dados do Usuário

## Problema Identificado

O workflow atual de envio de e-mail está gerando e-mails formatados corretamente, mas com problemas na inclusão de dados personalizados:

- O nome do usuário aparece como `[Nome do Usuário]` em vez do nome real
- Referências a `[Número de tarefas completas]` não são substituídas
- As tarefas específicas do usuário não estão sendo incluídas

## Solução

A solução envolve dois componentes principais:

1. **Pré-processamento do prompt**: Preparar um prompt enriquecido com dados reais antes de enviar para a IA
2. **Pós-processamento da resposta**: Substituir placeholders na resposta da IA com dados reais

### Novos Arquivos de Código

Dois novos arquivos foram criados para resolver o problema:

1. **`prepare_ai_email_prompt.js`**: Prepara os dados e enriquece o prompt antes de enviar para a IA
2. **`format_ai_email.js`**: Formata a resposta da IA e substitui placeholders com dados reais

## Configuração do Workflow no n8n

Para implementar esta solução, siga estes passos:

### 1. Adicionar Nó "Prepare AI Prompt"

1. Insira um novo nó "Code" antes do nó de chamada à API da IA
2. Nomeie como "Prepare AI Prompt"
3. Cole o conteúdo do arquivo `prepare_ai_email_prompt.js`
4. Conecte a saída deste nó à entrada do nó que chama a API da IA

### 2. Atualizar Nó de Formatação

1. Localize o nó "Code" que processa a resposta da IA
2. Substitua o código existente pelo conteúdo do arquivo `format_ai_email.js`

### 3. Conectar o Fluxo

Certifique-se de que os nós estejam conectados nesta ordem:
1. Nós de obtenção de dados do usuário e tarefas
2. "Prepare AI Prompt" (novo)
3. Chamada à API da IA
4. Formatação da resposta (atualizado)
5. Envio de e-mail

## Exemplo de Prompt Enriquecido

O novo formato de prompt inclui explicitamente os dados do usuário:

```
Gere um e-mail motivacional personalizado em HTML para João Silva.
A data atual é Quinta-feira, 16 de maio de 2025.

Informações para incluir:
- Tarefas para hoje: [{"title":"Finalizar relatório","priority":"high"},{"title":"Reunião com equipe","priority":"medium"}]
- Tarefas para amanhã: [{"title":"Planejar sprint","priority":"medium"}]
- Tarefas atrasadas: [{"title":"Enviar feedback","priority":"high"}]
- Total de tarefas: 8
- Tarefas concluídas: 4

Use estas informações específicas para personalizar o e-mail...
```

## Resultado Esperado

Após a implementação, o e-mail gerado deve:
1. Incluir o nome real do usuário no cumprimento
2. Mencionar a data atual
3. Listar as tarefas específicas do usuário
4. Incluir estatísticas corretas (total, concluídas, etc.)

## Solução de Problemas

Se ainda houver problemas:

1. Verifique os logs do n8n para identificar erros específicos
2. Confirme que os dados do usuário e tarefas estão chegando corretamente ao nó "Prepare AI Prompt"
3. Verifique se o modelo de IA está utilizando os dados fornecidos no prompt

## Exemplo de E-mail Correto

O e-mail corretamente formatado deve ter esta aparência:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Orga.AI - Resumo de Tarefas</title>
  <style><!-- estilos CSS --></style>
</head>
<body>
  <div class="header">
    <h1>Orga.AI - Seu Resumo Diário</h1>
    <p>Quinta-feira, 16 de maio de 2025</p>
  </div>
  
  <div class="container">
    <h2 style="color:#4A86E8">Olá, João Silva!</h2>
    <p>Você completou 4 de 8 tarefas...</p>
    <!-- conteúdo personalizado -->
  </div>
  
  <div class="footer">
    <p>Este email foi enviado automaticamente pelo sistema Orga.AI</p>
    <p>© 2025 Orga.AI - Sua vida organizada com inteligência</p>
  </div>
</body>
</html>
```
