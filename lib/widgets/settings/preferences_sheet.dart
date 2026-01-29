import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:physiq/providers/preferences_provider.dart';
import 'package:physiq/l10n/app_localizations.dart';

class PreferencesSheet extends ConsumerStatefulWidget {
  const PreferencesSheet({super.key});

  @override
  ConsumerState<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends ConsumerState<PreferencesSheet> {
  String _theme = 'light';
  String _units = 'metric';

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final l10n = AppLocalizations.of(context)!;
    
    // We don't use local state for language anymore, we rely on the provider
    // _theme and _units can remain local if not in provider yet, but typically should be in provider too.
    // For now I'll just focus on Language as requested.

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.preferences, style: AppTextStyles.heading2),
          const SizedBox(height: 24),
          _buildDropdown(
            l10n.language,
            prefs.locale.languageCode,
            {'en': 'English', 'hi': 'Hindi'},
            (val) {
               if (val != null) {
                 ref.read(preferencesProvider.notifier).setLocale(Locale(val));
               }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Theme',
            _theme,
            {'light': 'Light', 'dark': 'Dark'},
            (val) => setState(() => _theme = val!),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Units',
            _units,
            {'metric': 'Metric (kg/cm)', 'imperial': 'Imperial (lbs/ft)'},
            (val) => setState(() => _units = val!),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Save preferences via repository
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences saved')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value, style: AppTextStyles.bodyMedium));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
