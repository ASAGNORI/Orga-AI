// Formatar o conteúdo do email a partir da resposta da IA
const dados = $json;
let conteudoHTML = 'Não foi possível gerar o conteúdo do email.';

// Tenta extrair de vários formatos possíveis
if (dados.result) {
  conteudoHTML = dados.result;
} else if (dados.message && dados.message.content) {
  conteudoHTML = dados.message.content;
} else if (dados.response) {
  conteudoHTML = dados.response;
}

// Adicionar debugging
console.log('Dados recebidos da IA:', JSON.stringify(dados));
console.log('Conteúdo HTML extraído:', conteudoHTML.substring(0, 100) + '...');

// Return com HTML content
return [{
  json: {
    ...dados,
    emailHTML: conteudoHTML
  }
}];
