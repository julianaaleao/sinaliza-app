// 01 · Login e 02 · Login com erro
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/campos.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import 'layout_acesso.dart';
import 'rotas.dart';

class LoginPage extends StatefulWidget {
  // Aviso no topo do formulário (ex.: "Sua sessão expirou. Entre de novo.")
  final String? aviso;
  const LoginPage({super.key, this.aviso});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _chaveEmail = GlobalKey<CampoState>();
  bool _entrando = false;
  String? _erro;
  bool _erroNoEmail = false;

  @override
  void initState() {
    super.initState();
    _erro = widget.aviso;
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!(_chaveEmail.currentState?.validar() ?? true)) return;
    if (_senha.text.isEmpty) {
      setState(() => _erro = 'Digite a senha para entrar.');
      return;
    }
    setState(() {
      _entrando = true;
      _erro = null;
      _erroNoEmail = false;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      if (mounted) await irParaInicio(context);
    } on FirebaseAuthException catch (e) {
      // Não limpar o e-mail digitado; limpar só a senha
      _senha.clear();
      setState(() {
        switch (e.code) {
          case 'network-request-failed':
            _erro = 'Sem conexão com a internet. Conecte-se e tente de novo.';
          case 'too-many-requests':
            _erro = 'Muitas tentativas. Espere um pouco e tente de novo.';
          default:
            _erro = 'E-mail ou senha incorretos. Confira e tente de novo.';
            _erroNoEmail = true;
        }
      });
    } catch (e) {
      setState(() => _erro = 'Não foi possível entrar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutAcesso(
      alturaTopo: 292 - 44,
      sobreposicao: 48,
      topo: const CabecalhoAcesso(
        logo: true,
        titulo: 'Sinaliza',
        apoio: 'Converse em LIBRAS, sem barreiras.',
        tamanhoTitulo: 38,
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
                key: _chaveEmail,
                rotulo: 'E-mail',
                placeholder: 'voce@email.com',
                icone: Icone.email,
                controller: _email,
                teclado: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                validador: validarEmail,
                erro: _erroNoEmail ? 'Confira o e-mail' : null,
                onChanged: (_) {
                  if (_erroNoEmail) setState(() => _erroNoEmail = false);
                },
              ),
              const SizedBox(height: 16),
              Campo(
                rotulo: 'Senha',
                placeholder: 'Sua senha',
                icone: Icone.cadeado,
                controller: _senha,
                senha: true,
                autofill: const [AutofillHints.password],
                acao: TextInputAction.done,
                onSubmitted: (_) => _entrar(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: Cores.action,
                  ),
                  onPressed: () => Navigator.pushNamed(
                      context, Rotas.recuperarSenha,
                      arguments: _email.text.trim()),
                  child: Text('Esqueci minha senha',
                      style: Texto.fig(14, 18,
                          peso: FontWeight.w800, cor: Cores.action)),
                ),
              ),
              Botao('Entrar', carregando: _entrando, onPressed: _entrar),
            ],
          ),
        ),
      ),
      rodape: Column(
        children: [
          Text('Ainda não tem conta?',
              style: Texto.fig(15, 20,
                  peso: FontWeight.w600, cor: Cores.textMuted)),
          const SizedBox(height: 12),
          Botao(
            'Criar conta',
            tipo: TipoBotao.contorno,
            onPressed: () => Navigator.pushNamed(context, Rotas.cadastro),
          ),
        ],
      ),
    );
  }
}
