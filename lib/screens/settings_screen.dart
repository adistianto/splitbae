import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/currency_catalog.dart';

enum _LanguageChoice { device, english, indonesian }

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

_LanguageChoice _languageChoice(AppSettings s) {
  if (s.followSystemLocale) return _LanguageChoice.device;
  if (s.appLocaleCode == 'id') return _LanguageChoice.indonesian;
  return _LanguageChoice.english;
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final selected = _languageChoice(settings);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settingsLanguage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.settingsLanguageSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          _LanguageTile(
            label: l10n.languageDevice,
            selected: selected == _LanguageChoice.device,
            onTap: () => notifier.setFollowDeviceLanguage(),
          ),
          _LanguageTile(
            label: l10n.languageEnglish,
            selected: selected == _LanguageChoice.english,
            onTap: () => notifier.setExplicitLanguage('en'),
          ),
          _LanguageTile(
            label: l10n.languageIndonesian,
            selected: selected == _LanguageChoice.indonesian,
            onTap: () => notifier.setExplicitLanguage('id'),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.settingsDefaultCurrency,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.settingsDefaultCurrencySubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownMenu<String>(
              key: ValueKey(settings.defaultCurrencyCode),
              width: MediaQuery.sizeOf(context).width - 32,
              initialSelection: settings.defaultCurrencyCode,
              label: Text(l10n.currencyLabel),
              dropdownMenuEntries: [
                for (final code in kSupportedCurrencyCodes)
                  DropdownMenuEntry(
                    value: code,
                    label: currencyMenuLabel(code),
                  ),
              ],
              onSelected: (code) {
                if (code != null) notifier.setDefaultCurrency(code);
              },
            ),
          ),
        ],
      ),
    );
  }
}
