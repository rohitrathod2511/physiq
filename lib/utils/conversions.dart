

class Conversions {
  static double kgToLbs(double kg) {
    return kg * 2.20462;
  }

  static double lbsToKg(double lbs) {
    return lbs / 2.20462;
  }

  static double cmToFeet(double cm) {
    return cm / 30.48;
  }
  
  static double cmToInches(double cm) {
    return cm / 2.54;
  }

  static double feetInchesToCm(int feet, int inches) {
    return (feet * 30.48) + (inches * 2.54);
  }
  
  static String cmToFeetInchesString(double cm) {
    int totalInches = (cm / 2.54).round();
    int feet = totalInches ~/ 12;
    int inches = totalInches % 12;
    return "$feet' $inches\"";
  }
}
