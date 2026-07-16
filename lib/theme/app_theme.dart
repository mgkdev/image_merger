import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // グラスモーフィズム調のダークテーマ色定義
  static const Color backgroundColor = Color(0xFF0F0C20);
  static const Color cardColor = Color(0x1FFFFFFF); // 半透明の白
  static const Color cardBorderColor = Color(0x33FFFFFF); // より薄い半透明
  static const Color accentColor = Color(0xFF6C5CE7); // メインカラー（ネオンパープル）
  static const Color secondaryAccent = Color(0xFF00CEC9); // アクセントカラー2（シアン）
  static const Color textPrimaryColor = Color(0xFFF1F2F6);
  static const Color textSecondaryColor = Color(0xFFA4B0BE);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: secondaryAccent,
        surface: Color(0xFF1E1B30),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            titleLarge: GoogleFonts.outfit(
              textStyle: const TextStyle(
                color: textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            bodyLarge: const TextStyle(color: textPrimaryColor, fontSize: 16),
            bodyMedium: const TextStyle(
              color: textSecondaryColor,
              fontSize: 14,
            ),
          ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: secondaryAccent,
        overlayColor: secondaryAccent.withAlpha(40),
      ),
    );
  }

  // グラスモーフィズム調のカードデコレーション
  static BoxDecoration glassDecoration({
    double borderRadius = 16.0,
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? cardBorderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(50),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
