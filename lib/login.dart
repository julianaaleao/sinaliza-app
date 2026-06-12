import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/app_logo.dart';
import 'widgets/app_card.dart';
import 'widgets/app_button.dart';
import 'widgets/app_icon.dart';
import 'theme/app_colors.dart';

class LoginPage extends StatelessWidget {
  final txtEmail = TextEditingController();
  final txtSenha = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    const AppLogo(size: 72),
                    const SizedBox(height: 14),
                    Text(
                      'Sinaliza',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Acesse sua conta para continuar',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 40),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: txtEmail,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              hintText: 'seuemail@exemplo.com',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.35),
                                fontSize: 13,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(14),
                                child: AppIcon(
                                  icon: AppIcons.mail,
                                  size: 16,
                                  color: AppColors.support.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: txtSenha,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              hintText: 'Digite sua senha',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.35),
                                fontSize: 13,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(14),
                                child: AppIcon(
                                  icon: AppIcons.lock,
                                  size: 16,
                                  color: AppColors.support.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          AppGradientButton(
                            label: 'Entrar',
                            onPressed: () async {
                              try {
                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                  email: txtEmail.text.trim(),
                                  password: txtSenha.text.trim(),
                                );
                                Navigator.pushReplacementNamed(context, '/welcome');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                if (txtEmail.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Digite seu e-mail primeiro!'),
                                    ),
                                  );
                                  return;
                                }
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(
                                  email: txtEmail.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('E-mail de recuperação enviado!'),
                                  ),
                                );
                              },
                              child: Text(
                                'Esqueci minha senha',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem conta? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/registro'),
                          child: Text(
                            'Registrar',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}