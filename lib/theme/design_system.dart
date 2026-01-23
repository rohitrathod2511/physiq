import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';
import 'package:physiq/main.dart';

bool get _isDark {
  try {
    final mode = themeNotifier.value;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  } catch (e) {
    return false;
  }
}

// --- COLORS ---
class AppColors {
  static Color get background => _isDark ? const Color(0xFF121212) : const Color(0xFFF5F1ED);
  static Color get card => _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  
  // Text Colors
  static Color get primaryText => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  static Color get secondaryText => _isDark ? const Color(0xFFA0A0A0) : const Color(0xFF6B7280);
  
  // Accent & Brand Colors
  static Color get accent => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  
  // Primary Color Logic:
  // In Light Mode, Primary is Black.
  // In Dark Mode, we cannot use White because some widgets hardcode White text on top of Primary.
  // We use a Dark Grey that is visible against the Black background but dark enough to support White text.
  static Color get primary => _isDark ? const Color(0xFF333333) : const Color(0xFF000000);

  // Shadows
  static Color get shadow => _isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.06);
  
  // Static Constants (Unchanged unless needed dynamic, but these seem fixed)
  static const Color water = Color(0xFF60A5FA); 
  static const Color steps = Color(0xFF34D399); 
  
  static Color get textPrimary => primaryText;
}

// --- TEXT STYLES ---
class AppTextStyles {
  static TextStyle _base({FontWeight? weight, double? size, Color? color}) {
    return GoogleFonts.inter(fontWeight: weight, fontSize: size, color: color);
  }

  static TextStyle get heading1 => _base(
    weight: FontWeight.w800,
    size: 28,
    color: AppColors.primaryText,
  );

  static TextStyle get heading2 => _base(
    weight: FontWeight.w700,
    size: 20,
    color: AppColors.primaryText,
  );

  static TextStyle get largeNumber => _base(
    weight: FontWeight.w800,
    size: 56,
    color: AppColors.primaryText,
  );

  static TextStyle get nutrientValue => _base(
    weight: FontWeight.w700,
    size: 18,
    color: AppColors.primaryText,
  );

  static TextStyle get label => _base(
    weight: FontWeight.w500,
    size: 14,
    color: AppColors.secondaryText,
  );

  static TextStyle get smallLabel => _base(
    weight: FontWeight.w600,
    size: 11,
    color: AppColors.secondaryText,
  );

   static TextStyle get button => _base(
    weight: FontWeight.w600, 
    size: 14,
    color: AppColors.primaryText,
  );

  static TextStyle get body => _base(
    weight: FontWeight.normal,
    size: 16,
    color: AppColors.primaryText,
  );

  static TextStyle get bodyMedium => _base(
    weight: FontWeight.w500,
    size: 16,
    color: AppColors.primaryText,
  );

  static TextStyle get bodyBold => _base(
    weight: FontWeight.w700,
    size: 16,
    color: AppColors.primaryText,
  );

  static TextStyle get subheading => _base(
    weight: FontWeight.w500,
    size: 16,
    color: AppColors.secondaryText,
  );

  static TextStyle get h1 => heading1; 
  static TextStyle get h2 => heading2;
  static TextStyle get h3 => _base(weight: FontWeight.w600, size: 18, color: AppColors.primaryText);
  
  static TextStyle get heading3 => h3;

  static TextStyle get secondaryLabel => _base(
    weight: FontWeight.w500,
    size: 14,
    color: AppColors.secondaryText,
  );
}

// --- RADII & SHADOWS ---
class AppRadii {
  static const double bigCard = 28.0; 
  static const double smallCard = 16.0;

  static const double card = 24.0;
}

class AppShadows {
  static BoxShadow get card => BoxShadow(
    color: AppColors.shadow,
    blurRadius: 20,
    offset: const Offset(0, 8),
    spreadRadius: -4,
  );
}
