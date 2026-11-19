// Frases que o app reconhece e as respostas que aparecem para quem
// está com o celular. Cada resposta abre um GIF em LIBRAS de
// assets/respostas/ (lista dos arquivos em assets/respostas/LEIA-ME.txt).
//
// O id precisa ser igual ao da API (backend/api/frases.py).

import 'dart:math';

class Resposta {
  final String texto;

  // Um GIF por pessoa que gravou a resposta. O app alterna entre eles,
  // para cada integrante aparecer o mesmo número de vezes.
  final List<String> gifs;

  const Resposta(this.texto, this.gifs);
}

class Frase {
  final String id;
  final String texto;
  final List<Resposta> respostas;

  const Frase(this.id, this.texto, this.respostas);
}

// Respostas gravadas pela Juliana e pelo João
Resposta _dos2(String texto, String nome) =>
    Resposta(texto, ['${nome}_juliana.gif', '${nome}_joao.gif']);

final _naoSei = _dos2('Não sei', 'nao_sei');
final _naoEntendi = _dos2('Não entendi', 'nao_entendi');

final List<Frase> frases = [
  Frase('OLA_TUDO_BEM', 'Olá, tudo bem?', [
    _dos2('Estou bem', 'estou_bem'),
    _dos2('Não estou bem', 'nao_estou_bem'),
  ]),
  Frase('QUAL_SEU_NOME', 'Qual seu nome?', [
    const Resposta('Meu nome é...', ['meu_nome_juliana.gif']),
    _naoEntendi,
  ]),
  Frase('ONDE_BANHEIRO', 'Onde é o banheiro?', [
    _dos2('À direita', 'direita'),
    _dos2('À esquerda', 'esquerda'),
    _naoSei,
  ]),
  Frase('QUANTO_CUSTA', 'Quanto custa?', [
    _dos2('É de graça', 'gratis'),
    _naoSei,
  ]),
  Frase('QUE_HORAS', 'Que horas são?', [
    _dos2('É 1 hora', 'uma_hora'),
    _dos2('São 2 horas', 'duas_horas'),
    _dos2('São 3 horas', 'tres_horas'),
    _naoSei,
  ]),
];

// Alterna Juliana e João a cada resposta mostrada (em qualquer frase),
// começando por um dos dois ao acaso. Assim os dois aparecem o mesmo
// número de vezes, mesmo quando cada resposta é tocada uma vez só.
int _proximaPessoa = Random().nextInt(2);

String proximoGif(Resposta resposta) {
  if (resposta.gifs.length == 1) return resposta.gifs.first;
  final gif = resposta.gifs[_proximaPessoa % resposta.gifs.length];
  _proximaPessoa++;
  return gif;
}

Frase? fraseDoId(String id) {
  for (final f in frases) {
    if (f.id == id) return f;
  }
  return null;
}
