import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:social_media/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: AppTheme.glassBoxDecoration,
          child: child,
        ),
      ),
    );
  }
}