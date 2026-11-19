import 'package:flutter/material.dart';

import 'frases.dart';
import 'theme/app_colors.dart';
import 'widgets/app_button.dart';

// Painel que aparece depois que uma frase é reconhecida: mostra a frase
// e as respostas. Devolve true se a pessoa pediu para ler de novo.
Future<bool> mostrarRespostas(BuildContext context, Frase frase) async {
  final theme = Theme.of(context);
  final lerDeNovo = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'A pessoa disse:',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              frase.texto,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Escolha a resposta para mostrar em LIBRAS:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final resposta in frase.respostas) ...[
              AppGradientButton(
                label: resposta.texto,
                onPressed: () => mostrarGif(context, resposta),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            AppSecondaryButton(
              label: 'Não é essa frase? Ler de novo',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    ),
  );
  return lerDeNovo ?? false;
}

// Tela cheia com o GIF da resposta, virada para a pessoa surda ver
Future<void> mostrarGif(BuildContext context, Resposta resposta) {
  final theme = Theme.of(context);
  final gif = proximoGif(resposta);
  return showDialog(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/respostas/$gif',
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (context, _, __) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'GIF ainda não gravado:\nassets/respostas/$gif',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Text(
                resposta.texto,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
