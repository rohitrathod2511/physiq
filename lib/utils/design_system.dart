import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- COLORS ---
class AppColors {
  static const Color background = Color(0xFFF2F4F7); // Soft pastel/greyish background
  static const Color card = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color accent = Color(0xFF111827); // Black accent
  static Color shadow = Colors.black.withOpacity(0.06);
  static const Color water = Color(0xFF60A5FA); 
  static const Color steps = Color(0xFF34D399); 
  static const Color textPrimary = primaryText;

  static get primary => null; // Alias for compatibility
}

// --- TEXT STYLES ---
class AppTextStyles {
  static TextStyle _base({FontWeight? weight, double? size, Color? color}) {
    return GoogleFonts.inter(fontWeight: weight, fontSize: size, color: color);
  }

  static final TextStyle heading1 = _base(
    weight: FontWeight.w800,
    size: 28,
    color: AppColors.primaryText,
  );

  static final TextStyle heading2 = _base(
    weight: FontWeight.w700,
    size: 20,
    color: AppColors.primaryText,
  );

  static final TextStyle largeNumber = _base(
    weight: FontWeight.w800,
    size: 56, // Larger for the main calorie count
    color: AppColors.primaryText,
  );

  static final TextStyle nutrientValue = _base(
    weight: FontWeight.w700,
    size: 18,
    color: AppColors.primaryText,
  );

  static final TextStyle label = _base(
    weight: FontWeight.w500,
    size: 14,
    color: AppColors.secondaryText,
  );

  static final TextStyle smallLabel = _base(
    weight: FontWeight.w600,
    size: 11,
    color: AppColors.secondaryText,
  );

   static final TextStyle button = _base(
    weight: FontWeight.w600, 
    size: 14,
    color: AppColors.primaryText,
  );

  static final TextStyle body = _base(
    weight: FontWeight.normal,
    size: 16,
    color: AppColors.primaryText,
  );

  static final TextStyle bodyMedium = _base(
    weight: FontWeight.w500,
    size: 16,
    color: AppColors.primaryText,
  );

  static final TextStyle bodyBold = _base(
    weight: FontWeight.w700,
    size: 16,
    color: AppColors.primaryText,
  );

  static final TextStyle subheading = _base(
    weight: FontWeight.w500,
    size: 16,
    color: AppColors.secondaryText,
  );

  static get h1 => null;
}

// --- RADII & SHADOWS ---
class AppRadii {
  static const double bigCard = 28.0; // Slightly more rounded
  static const double smallCard = 20.0;

  static const double card = 24.0;
}

class AppShadows {
  static final BoxShadow card = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 20,
    offset: const Offset(0, 8),
    spreadRadius: -4,
  );
}
