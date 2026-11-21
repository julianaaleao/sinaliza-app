// Chamadas à API de reconhecimento (mesmas rotas e tempos de antes do
// redesign; a lógica saiu de camera.dart sem mudanças de comportamento).
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// Padrão: API no Railway. Para testar local:
// flutter run --dart-define=API_URL=http://127.0.0.1:8000
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://sinaliza-app-production.up.railway.app',
);

// Frases: grava ~5s (igual a DURACAO_SEGUNDOS da API)
const janelaFrase = Duration(seconds: 5);
// Vogais: cada leitura grava ~1,5s de frames
const janelaVogal = Duration(milliseconds: 1500);
// Menos frames = servidor responde mais rápido
const intervaloFrames = Duration(milliseconds: 200);

// Falha de rede (sem internet ou API fora do ar): leva ao estado offline
class SemConexao implements Exception {}

// A API respondeu, mas com erro (ex.: modelo não treinado)
class ErroApi implements Exception {
  final int status;
  ErroApi(this.status);
}

class ResultadoFrase {
  final String fraseId; // vazio se não reconheceu
  final double? confianca;
  final bool maosDetectadas;
  ResultadoFrase(this.fraseId, this.confianca, this.maosDetectadas);
}

class ResultadoVogal {
  final String resultado; // vogal ou gesto (ex.: OI); vazio se nada
  final bool maosDetectadas;
  ResultadoVogal(this.resultado, this.maosDetectadas);
}

class Api {
  // Acorda a API no Railway (pode demorar no primeiro acesso)
  static Future<bool> saude(
      {Duration limite = const Duration(seconds: 60)}) async {
    try {
      final r = await http.get(Uri.parse('$apiUrl/saude')).timeout(limite);
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> _post(
      String rota, List<String> imagens, List<int> tempos, Duration limite) async {
    final http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('$apiUrl/$rota'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'imagens': imagens, 'tempos_ms': tempos}),
          )
          .timeout(limite);
    } on TimeoutException {
      rethrow;
    } catch (_) {
      throw SemConexao();
    }
    if (r.statusCode != 200) throw ErroApi(r.statusCode);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<ResultadoFrase> reconhecerFrase(
      List<String> imagens, List<int> tempos) async {
    final d = await _post(
        'reconhecer_frase', imagens, tempos, const Duration(seconds: 20));
    return ResultadoFrase(
      d['frase'] as String? ?? '',
      (d['confianca'] as num?)?.toDouble(),
      d['detectado'] == true,
    );
  }

  static Future<ResultadoVogal> reconhecerVogal(
      List<String> imagens, List<int> tempos) async {
    final d = await _post(
        'reconhecer_sequencia', imagens, tempos, const Duration(seconds: 10));
    return ResultadoVogal(
      d['resultado'] as String? ?? '',
      d['detectado'] as bool? ?? false,
    );
  }
}
