import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0D9488); // Deep Teal/Emerald
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean Light Slate
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkSurfaceCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // Debt Types
  // دين لي (مستحق لي من الشخص) - إيجابي وأخضر
  static const Color debtForMe = Color(0xFF10B981);
  static const Color debtForMeDark = Color(0xFF059669);
  static const Color debtForMeLight = Color(0xFFD1FAE5);

  // دين علي (مطلوب مني للشخص) - سلبي وأحمر/وردي
  static const Color debtOnMe = Color(0xFFF43F5E);
  static const Color debtOnMeDark = Color(0xFFE11D48);
  static const Color debtOnMeLight = Color(0xFFFFE4E6);

  // Currencies
  static const Color currencyIQD = Color(0xFF0284C7); // Sky Blue for Dinar
  static const Color currencyIQDLight = Color(0xFFE0F2FE);
  static const Color currencyUSD = Color(0xFFD97706); // Amber Gold for Dollar
  static const Color currencyUSDLight = Color(0xFFFEF3C7);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // 3D Shadows
  static List<BoxShadow> softShadow3D({Color? shadowColor}) {
    return [
      BoxShadow(
        color: (shadowColor ?? Colors.black).withOpacity(0.06),
        offset: const Offset(0, 8),
        blurRadius: 20,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: (shadowColor ?? Colors.black).withOpacity(0.04),
        offset: const Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> raisedShadow3D({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? primary).withOpacity(0.28),
        offset: const Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: (color ?? primary).withOpacity(0.12),
        offset: const Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ];
  }

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );

  static const LinearGradient debtForMeGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient debtOnMeGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
  );
}
