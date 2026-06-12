import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class AppIcons {
  static const mail = 'mail';
  static const lock = 'lock';
  static const user = 'user';
  static const history = 'history';
  static const logout = 'log-out';
  static const play = 'play';
  static const stopCircle = 'stop-circle';
  static const close = 'x';
}

class AppIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const AppIcon({
    super.key,
    required this.icon,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'public/icons/lucide/$icon.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? AppColors.secondary,
        BlendMode.srcIn,
      ),
      semanticsLabel: semanticLabel,
    );
  }
}
