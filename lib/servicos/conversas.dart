// Histórico de conversas no Firestore (coleção "conversas").
// Uma conversa (sessão) começa na primeira troca concluída e termina em
// Encerrar, ao sair da conta ou após 30 min sem interação.
//
// Documento: { uid, inicio, atualizado, mensagens: [
//   { autor: "surda" | "voce", texto, fraseId?, em (ms desde 1970) } ] }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Mensagem {
  final bool surda;
  final String texto;
  final String? fraseId;
  final DateTime em;

  Mensagem({
    required this.surda,
    required this.texto,
    this.fraseId,
    DateTime? em,
  }) : em = em ?? DateTime.now();

  Map<String, dynamic> paraMapa() => {
        'autor': surda ? 'surda' : 'voce',
        'texto': texto,
        if (fraseId != null) 'fraseId': fraseId,
        'em': em.millisecondsSinceEpoch,
      };

  static Mensagem deMapa(Map<String, dynamic> m) => Mensagem(
        surda: m['autor'] == 'surda',
        texto: m['texto'] as String? ?? '',
        fraseId: m['fraseId'] as String?,
        em: DateTime.fromMillisecondsSinceEpoch(
            (m['em'] as num?)?.toInt() ?? 0),
      );
}

class Conversa {
  final String id;
  final DateTime inicio;
  final List<Mensagem> mensagens;
  Conversa(this.id, this.inicio, this.mensagens);

  String get primeiraFrase => mensagens
      .firstWhere((m) => m.surda,
          orElse: () => Mensagem(surda: true, texto: ''))
      .texto;

  String get primeiraResposta => mensagens
      .firstWhere((m) => !m.surda,
          orElse: () => Mensagem(surda: false, texto: ''))
      .texto;

  static Conversa deDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final ts = m['inicio'];
    final inicio = ts is Timestamp
        ? ts.toDate()
        : DateTime.fromMillisecondsSinceEpoch(
            (m['inicioMs'] as num?)?.toInt() ?? 0);
    final lista = (m['mensagens'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Mensagem.deMapa(Map<String, dynamic>.from(e)))
        .toList();
    return Conversa(d.id, inicio, lista);
  }
}

class Conversas {
  static final _col = FirebaseFirestore.instance.collection('conversas');
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Lista as conversas do usuário, mais recentes primeiro. Ordena no app
  // para não precisar de índice composto no Firestore.
  static Stream<List<Conversa>> doUsuario() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _col.where('uid', isEqualTo: uid).snapshots().map((s) {
      final l = s.docs.map(Conversa.deDoc).toList()
        ..sort((a, b) => b.inicio.compareTo(a.inicio));
      return l;
    });
  }

  static Stream<Conversa?> porId(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Conversa.deDoc(d) : null);

  // Cria a conversa e devolve o id
  static Future<String?> criar(List<Mensagem> mensagens) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final ref = await _col.add({
        'uid': uid,
        'inicio': FieldValue.serverTimestamp(),
        'atualizado': FieldValue.serverTimestamp(),
        'mensagens': mensagens.map((m) => m.paraMapa()).toList(),
      });
      return ref.id;
    } catch (e) {
      debugPrint('Erro ao salvar conversa: $e');
      return null;
    }
  }

  static Future<void> atualizar(String id, List<Mensagem> mensagens) async {
    try {
      await _col.doc(id).update({
        'atualizado': FieldValue.serverTimestamp(),
        'mensagens': mensagens.map((m) => m.paraMapa()).toList(),
      });
    } catch (e) {
      debugPrint('Erro ao atualizar conversa: $e');
    }
  }

  static Future<void> excluir(String id) => _col.doc(id).delete();

  static Future<void> apagarTudo() async {
    final uid = _uid;
    if (uid == null) return;
    final docs = await _col.where('uid', isEqualTo: uid).get();
    final lote = FirebaseFirestore.instance.batch();
    for (final d in docs.docs) {
      lote.delete(d.reference);
    }
    await lote.commit();
  }
}

// Conversa em andamento na tela de Reconhecimento. Grava no Firestore
// a cada troca concluída (se "Salvar histórico" estiver ligado).
class SessaoAtual {
  static const _inatividade = Duration(minutes: 30);

  final List<Mensagem> mensagens = [];
  String? _docId;
  DateTime _ultimaInteracao = DateTime.now();

  bool get vazia => mensagens.isEmpty;

  // Depois de 30 min sem interação, a próxima troca começa outra sessão
  void tocar() {
    if (DateTime.now().difference(_ultimaInteracao) > _inatividade) {
      encerrar();
    }
    _ultimaInteracao = DateTime.now();
  }

  // Grava a troca (frase da pessoa surda + resposta escolhida)
  Future<void> adicionarTroca(
      String frase, String fraseId, String resposta, bool salvar) async {
    tocar();
    mensagens
      ..add(Mensagem(surda: true, texto: frase, fraseId: fraseId))
      ..add(Mensagem(surda: false, texto: resposta, fraseId: fraseId));
    await _gravar(salvar);
  }

  // "Outra resposta": substitui a última resposta, sem duplicar
  Future<void> trocarUltimaResposta(String resposta, bool salvar) async {
    tocar();
    final i = mensagens.lastIndexWhere((m) => !m.surda);
    if (i < 0) return;
    final antiga = mensagens[i];
    mensagens[i] =
        Mensagem(surda: false, texto: resposta, fraseId: antiga.fraseId);
    await _gravar(salvar);
  }

  Future<void> _gravar(bool salvar) async {
    if (!salvar) return;
    if (_docId == null) {
      _docId = await Conversas.criar(mensagens);
    } else {
      await Conversas.atualizar(_docId!, mensagens);
    }
  }

  void encerrar() {
    mensagens.clear();
    _docId = null;
  }
}
