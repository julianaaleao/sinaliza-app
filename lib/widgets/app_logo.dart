import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withBackground;
  final bool white;

  const AppLogo({
    super.key,
    this.size = 80,
    this.withBackground = true,
    this.white = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = withBackground ? size * 0.6 : size;
    final logo = Image.asset(
      white
          ? 'public/images/sinaliza-logo-white.png'
          : 'public/images/sinaliza-logo.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      semanticLabel: 'Logo do Sinaliza',
    );

    if (!withBackground) {
      return logo;
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppGradients.highlight,
        shape: BoxShape.circle,
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Center(child: logo),
      ),
    );
  }
}