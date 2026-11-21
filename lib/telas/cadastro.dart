// 03 · Cadastro. "Criar conta" fica desativado até nome, e-mail e
// senha (mín. 8 caracteres) serem válidos.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/campos.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import 'layout_acesso.dart';
import 'rotas.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _criando = false;
  String? _erro;
  String? _erroEmail;

  bool get _valido =>
      _nome.text.trim().isNotEmpty &&
      validarEmail(_email.text.trim()) == null &&
      _senha.text.length >= 8;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _criando = true;
      _erro = null;
      _erroEmail = null;
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_nome.text.trim());
      if (!mounted) return;
      // Conta nova: sempre mostra as boas-vindas
      Navigator.pushNamedAndRemoveUntil(
          context, Rotas.boasVindas, (_) => false);
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _erroEmail = 'Este e-mail já tem conta. Tente entrar.';
          case 'invalid-email':
            _erroEmail = 'Confira o e-mail';
          case 'weak-password':
            _erro = 'Escolha uma senha mais forte.';
          case 'network-request-failed':
            _erro = 'Sem conexão com a internet. Conecte-se e tente de novo.';
          default:
            _erro = 'Não foi possível criar a conta. Tente de novo.';
        }
      });
    } catch (_) {
      setState(() => _erro = 'Não foi possível criar a conta. Tente de novo.');
    } finally {
      if (mounted) setState(() => _criando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void mudou(String _) => setState(() => _erroEmail = null);

    return LayoutAcesso(
      alturaTopo: 268 - 44,
      topo: CabecalhoAcesso(
        titulo: 'Crie sua conta',
        apoio: 'Comece a sinalizar em poucos passos.',
        voltar: () => Navigator.maybePop(context),
        rotuloVoltar: 'Voltar ao login',
      ),
      cartao: CartaoForm(
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_erro != null) ...[
                FaixaErro(_erro!),
                const SizedBox(height: 16),
              ],
              Campo(
                rotulo: 'Nome',
                placeholder: 'Como podemos te chamar?',
                icone: Icone.usuario,
                controller: _nome,
                autofill: const [AutofillHints.name],
                validador: (v) => v.isEmpty ? 'Digite seu nome' : null,
                onChanged: mudou,
              ),
              const SizedBox(height: 16),
              Campo(
                rotulo: 'E-mail',
                placeholder: 'voce@email.com',
                icone: Icone.email,
                controller: _email,
                teclado: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                validador: validarEmail,
                erro: _erroEmail,
                onChanged: mudou,
              ),
              const SizedBox(height: 16),
              Campo(
                rotulo: 'Senha',
                dica: 'mín. 8 caracteres',
                placeholder: 'Crie uma senha',
                icone: Icone.cadeado,
                controller: _senha,
                senha: true,
                autofill: const [AutofillHints.newPassword],
                acao: TextInputAction.done,
                validador: (v) =>
                    v.length < 8 ? 'Use pelo menos 8 caracteres' : null,
                onChanged: mudou,
                onSubmitted: (_) => _valido ? _criar() : null,
              ),
              // Espaço reservado para termos de uso e política (etapa futura)
              const SizedBox(height: 16),
              Botao('Criar conta',
                  carregando: _criando,
                  onPressed: _valido ? _criar : null),
            ],
          ),
        ),
      ),
      rodape: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Já tem conta? ',
              style: Texto.fig(15, 20,
                  peso: FontWeight.w600, cor: Cores.textMuted)),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: () => Navigator.maybePop(context),
            child: Text('Entrar',
                style: Texto.fig(15, 20,
                    peso: FontWeight.w800, cor: Cores.action)),
          ),
        ],
      ),
    );
  }
}
