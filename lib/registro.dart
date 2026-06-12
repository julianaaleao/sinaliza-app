import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/app_logo.dart';
import 'widgets/app_card.dart';
import 'widgets/app_button.dart';
import 'widgets/app_icon.dart';
import 'theme/app_colors.dart';

class RegistroPage extends StatelessWidget {
  final txtNome = TextEditingController();
  final txtEmail = TextEditingController();
  final txtSenha = TextEditingController();

  RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogo(size: 72),
                const SizedBox(height: 14),
                Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Comece a sinalizar em poucos passos',
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
                        controller: txtNome,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          labelText: 'Nome',
                          hintText: 'Seu nome completo',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.35),
                            fontSize: 13,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(14),
                            child: AppIcon(
                              icon: AppIcons.user,
                              size: 16,
                              color: AppColors.support.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Crie uma senha segura',
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
                        label: 'Registrar',
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: txtEmail.text.trim(),
                              password: txtSenha.text.trim(),
                            );
                            await FirebaseAuth.instance.currentUser
                                ?.updateDisplayName(txtNome.text.trim());
                            Navigator.of(context)
                              ..pop()
                              ..pushReplacementNamed('/welcome');
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppSecondaryButton(
                    label: 'Voltar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}