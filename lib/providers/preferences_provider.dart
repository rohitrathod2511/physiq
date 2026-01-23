import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferencesState {
  final ThemeMode themeMode;
  final Locale locale;

  PreferencesState({required this.themeMode, required this.locale});

  PreferencesState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return PreferencesState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PreferencesNotifier(this._prefs)
      : super(PreferencesState(
          themeMode: _parseThemeMode(_prefs.getString('app_theme')),
          locale: Locale(_prefs.getString('app_language') ?? 'en'),
        ));

  static ThemeMode _parseThemeMode(String? value) {
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    
    await _prefs.setString('app_theme', modeStr);
    await _syncToFirestore({'theme': modeStr});
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString('app_language', locale.languageCode);
    await _syncToFirestore({'language': locale.languageCode});
  }

  Future<void> _syncToFirestore(Map<String, dynamic> prefs) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'preferences': prefs
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error syncing prefs: $e');
      }
    }
  }
  
  Future<void> clear() async {
    await _prefs.remove('app_theme');
    await _prefs.remove('app_language');
    // Reset state to defaults
    state = PreferencesState(themeMode: ThemeMode.light, locale: const Locale('en'));
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Override in main.dart
});

final preferencesProvider = StateNotifierProvider<PreferencesNotifier, PreferencesState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesNotifier(prefs);
});
