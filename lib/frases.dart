// Frases que o app reconhece e as respostas que aparecem para quem
// está com o celular. Cada resposta abre um GIF em LIBRAS de
// assets/respostas/ (lista dos arquivos em assets/respostas/LEIA-ME.txt).
//
// O id precisa ser igual ao da API (backend/api/frases.py).

class Resposta {
  final String texto;
  final String gif;

  // Mostra a hora atual em números grandes junto com o GIF
  final bool mostraHora;

  const Resposta(this.texto, this.gif, {this.mostraHora = false});
}

class Frase {
  final String id;
  final String texto;
  final List<Resposta> respostas;

  const Frase(this.id, this.texto, this.respostas);
}

const _naoSei = Resposta('Não sei', 'nao_sei.gif');
const _naoEntendi = Resposta('Não entendi', 'nao_entendi.gif');

const List<Frase> frases = [
  Frase('OLA_TUDO_BEM', 'Olá, tudo bem?', [
    Resposta('Sim, tudo bem!', 'sim_tudo_bem.gif'),
    Resposta('Não estou bem', 'nao_estou_bem.gif'),
  ]),
  Frase('QUAL_SEU_NOME', 'Qual seu nome?', [
    Resposta('Meu nome é...', 'meu_nome.gif'),
    _naoEntendi,
  ]),
  Frase('ONDE_BANHEIRO', 'Onde é o banheiro?', [
    Resposta('À direita', 'direita.gif'),
    Resposta('À esquerda', 'esquerda.gif'),
    Resposta('Em frente', 'em_frente.gif'),
    _naoSei,
  ]),
  Frase('QUANTO_CUSTA', 'Quanto custa?', [
    Resposta('É grátis', 'gratis.gif'),
    Resposta('Vou chamar alguém', 'vou_chamar_alguem.gif'),
    _naoSei,
  ]),
  Frase('QUE_HORAS', 'Que horas são?', [
    Resposta('Agora são...', 'agora_sao.gif', mostraHora: true),
    _naoSei,
  ]),
];

Frase? fraseDoId(String id) {
  for (final f in frases) {
    if (f.id == id) return f;
  }
  return null;
}
