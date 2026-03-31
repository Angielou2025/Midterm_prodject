import 'package:flutter/material.dart';

class AppTheme {
  // Mas matapang at modern na primary color (Royal Purple/Blue)
  static const Color primaryButtonColor = Color(0xFF6366F1);
  static const Color accentColor = Color(0xFF8B5CF6);

  static const String backgroundImage = 'https://i.ibb.co/L5rQ9vT/anime-auth-bg.jpg';

  static BoxDecoration glassBoxDecoration = BoxDecoration(
    // Ginawang mas "frosted" at may manipis na border
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(25),
    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  );

  static InputDecoration inputFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      // Mas dark nang konti para mabasa ang puting text
      fillColor: Colors.black.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }
}