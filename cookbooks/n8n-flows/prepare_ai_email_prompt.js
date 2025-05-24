// Script para preparar os dados para o prompt de IA
// Este script deve ser usado no nó Code antes de chamar a API de IA
// Para enriquecer os dados e garantir que placeholders sejam substituídos

/**
 * @param {Object} usuario - Dados do usuário
 * @param {Array} tarefasHoje - Lista de tarefas para hoje
 * @param {Array} tarefasAmanha - Lista de tarefas para amanhã
 * @param {Array} tarefasAtrasadas - Lista de tarefas atrasadas
 * @returns {Object} - Dados enriquecidos para o prompt de IA
 */
function prepareAIEmailPrompt(item) {
  // Log para debug dos dados de entrada
  console.log('Preparando dados para IA');
  
  // Obter dados do nó "Processar Dados do Usuário"
  const usuario = item.json;
  
  // Verificar e padronizar dados do usuário
  const dadosUsuario = {
    id: usuario.id || 'desconhecido',
    nome: usuario.nome || usuario.name || (usuario.email ? usuario.email.split('@')[0] : 'Usuário'),
    email: usuario.email || '',
    dataFormatada: usuario.dataFormatada || new Date().toLocaleDateString('pt-BR')
  };
  
  // Processar tarefas hoje
  const tarefasHojeFormatadas = formatarListaTarefas(usuario.tarefasHoje || []);
  
  // Processar tarefas amanhã
  const tarefasAmanhaFormatadas = formatarListaTarefas(usuario.tarefasAmanha || []);
  
  // Processar tarefas atrasadas
  const tarefasAtrasadasFormatadas = formatarListaTarefas(usuario.tarefasAtrasadas || []);
  
  // Estatísticas
  const estatisticas = {
    totalTarefas: usuario.totalTarefas || 0,
    tarefasConcluidas: usuario.tarefasConcluidas || 0,
    tarefasHoje: (usuario.tarefasHoje || []).length,
    tarefasAmanha: (usuario.tarefasAmanha || []).length,
    tarefasAtrasadas: (usuario.tarefasAtrasadas || []).length,
  };
  
  // Formatar o prompt final com dados reais (não placeholders)
  const prompt = `
Gere um e-mail motivacional e personalizado em HTML para o usuário com as informações fornecidas abaixo.
O e-mail deve ser objetivo, positivo e destacar conquistas, próximos passos e incentivar o usuário a planejar o dia.

DADOS DO USUÁRIO:
- Nome: ${dadosUsuario.nome}
- Email: ${dadosUsuario.email}
- Data: ${dadosUsuario.dataFormatada}

ESTATÍSTICAS:
- Total de tarefas: ${estatisticas.totalTarefas}
- Tarefas concluídas: ${estatisticas.tarefasConcluidas}
- Taxa de conclusão: ${estatisticas.totalTarefas > 0 ? Math.round((estatisticas.tarefasConcluidas / estatisticas.totalTarefas) * 100) : 0}%

TAREFAS PARA HOJE (${estatisticas.tarefasHoje}):
${tarefasHojeFormatadas}

TAREFAS PARA AMANHÃ (${estatisticas.tarefasAmanha}):
${tarefasAmanhaFormatadas}

TAREFAS ATRASADAS (${estatisticas.tarefasAtrasadas}):
${tarefasAtrasadasFormatadas}

O email deve incluir:
1. Uma saudação personalizada com o nome do usuário
2. Um resumo do progresso (tarefas concluídas vs. total)
3. Seções organizadas para as tarefas de hoje, amanhã e atrasadas (se houver)
4. Uma mensagem motivacional para o dia
5. Usar formatação HTML adequada com <p>, <ul>, <li>, <h2>, <h3> etc.

Use formatação HTML para organização e destaque visual. Não inclua placeholders ou variáveis, use apenas os dados reais fornecidos acima.
`;

  // Retornar dados formatados para o nó de API
  return {
    json: {
      prompt: prompt,
      dadosUsuario: dadosUsuario,
      estatisticas: estatisticas
    }
  };
}

/**
 * Formata uma lista de tarefas para exibição no prompt
 * @param {Array} tarefas - Lista de tarefas 
 * @returns {String} - Texto formatado para o prompt
 */
function formatarListaTarefas(tarefas) {
  if (!tarefas || tarefas.length === 0) {
    return "Nenhuma tarefa encontrada.";
  }
  
  return tarefas.map(tarefa => {
    const prioridade = {
      'high': 'Alta',
      'medium': 'Média', 
      'low': 'Baixa'
    }[tarefa.priority] || 'Normal';
    
    const status = {
      'todo': 'Pendente',
      'doing': 'Em andamento',
      'done': 'Concluída'
    }[tarefa.status] || 'Pendente';
    
    return `- ${tarefa.title} (Prioridade: ${prioridade}, Status: ${status})`;
  }).join('\n');
}

// Exportar a função para uso no n8n
module.exports = {
  prepareAIEmailPrompt
};

// Para teste direto no nó Code do n8n
return prepareAIEmailPrompt($input.item);
