import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- COLORS ---
class AppColors {
  static const Color background = Color(0xFFF5F1ED);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF7B7B7B);
  static const Color accent = Color(0xFF000000);
  static Color shadow = Colors.black.withOpacity(0.08);
  static const Color water = Color(0xFF5AC8FA); // A more vibrant blue
  static const Color steps = Color(0xFFA5D6A7); // A soft green
  static const Color textPrimary = primaryText;

  static get primary => null; // Alias for compatibility
}

// --- TEXT STYLES ---
class AppTextStyles {
  static TextStyle _base({FontWeight? weight, double? size, Color? color}) {
    return GoogleFonts.inter(fontWeight: weight, fontSize: size, color: color);
  }

  static final TextStyle heading1 = _base(
    weight: FontWeight.bold,
    size: 28,
    color: AppColors.primaryText,
  );

  static final TextStyle heading2 = _base(
    weight: FontWeight.bold,
    size: 20,
    color: AppColors.primaryText,
  );

  static final TextStyle largeNumber = _base(
    weight: FontWeight.bold,
    size: 48,
    color: AppColors.primaryText,
  );

  static final TextStyle nutrientValue = _base(
    weight: FontWeight.bold,
    size: 18,
    color: AppColors.primaryText,
  );

  static final TextStyle label = _base(
    weight: FontWeight.w500, // Medium weight
    size: 14,
    color: AppColors.secondaryText,
  );

  static final TextStyle smallLabel = _base(
    weight: FontWeight.w500, // Medium weight
    size: 12,
    color: AppColors.secondaryText,
  );

   static final TextStyle button = _base(
    weight: FontWeight.bold, 
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
    weight: FontWeight.bold,
    size: 16,
    color: AppColors.primaryText,
  );

  static final TextStyle subheading = _base(
    weight: FontWeight.w500,
    size: 16,
    color: AppColors.secondaryText,
  );
}

// --- RADII & SHADOWS ---
class AppRadii {
  static const double bigCard = 24.0;
  static const double smallCard = 16.0;

  static double? get card => null;
}

class AppShadows {
  static final BoxShadow card = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 12,
    offset: const Offset(0, 6),
  );
}
