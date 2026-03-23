import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/theme/dynamic_color_support.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/screens/backup_screen.dart';
import 'package:splitbae/widgets/settings_v0_activity_insights.dart';
import 'package:splitbae/currency_catalog.dart';
import 'package:splitbae/providers.dart';

enum _LanguageChoice { device, english, indonesian }

bool _useExpressiveComponents(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.android;
}

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

class _LanguageChoiceSegment extends StatelessWidget {
  const _LanguageChoiceSegment({
    required this.selected,
    required this.onSelected,
  });

  final _LanguageChoice selected;
  final ValueChanged<_LanguageChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_LanguageChoice>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<_LanguageChoice>(
          value: _LanguageChoice.device,
          icon: const Icon(Icons.phone_iphone_outlined),
          label: Text(l10n.languageDevice),
        ),
        ButtonSegment<_LanguageChoice>(
          value: _LanguageChoice.english,
          icon: const Icon(Icons.language_outlined),
          label: Text(l10n.languageEnglish),
        ),
        ButtonSegment<_LanguageChoice>(
          value: _LanguageChoice.indonesian,
          icon: const Icon(Icons.translate_outlined),
          label: Text(l10n.languageIndonesian),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) {
        final choice = values.firstOrNull;
        if (choice != null) onSelected(choice);
      },
    );
  }
}

_LanguageChoice _languageChoice(AppSettings s) {
  if (s.followSystemLocale) return _LanguageChoice.device;
  if (s.appLocaleCode == 'id') return _LanguageChoice.indonesian;
  return _LanguageChoice.english;
}

enum _ThemeChoice { system, light, dark }

_ThemeChoice _themeChoice(AppSettings s) {
  switch (s.themeModeCode) {
    case 'light':
      return _ThemeChoice.light;
    case 'dark':
      return _ThemeChoice.dark;
    default:
      return _ThemeChoice.system;
  }
}

/// Follow-device row: Apple uses “Automatic”; Material platforms use “System default”.
String _themeFollowDeviceLabel(AppLocalizations l10n) {
  return hostPlatformIsApple()
      ? l10n.settingsThemeFollowDeviceApple
      : l10n.settingsThemeFollowDeviceMaterial;
}

class _ThemeChoiceSegment extends StatelessWidget {
  const _ThemeChoiceSegment({
    required this.selected,
    required this.onSelected,
  });

  final _ThemeChoice selected;
  final ValueChanged<_ThemeChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_ThemeChoice>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<_ThemeChoice>(
          value: _ThemeChoice.system,
          icon: const Icon(Icons.brightness_auto_outlined),
          label: Text(l10n.settingsThemeFollowDeviceMaterialShort),
        ),
        ButtonSegment<_ThemeChoice>(
          value: _ThemeChoice.light,
          icon: const Icon(Icons.light_mode_outlined),
          label: Text(l10n.settingsThemeLight),
        ),
        ButtonSegment<_ThemeChoice>(
          value: _ThemeChoice.dark,
          icon: const Icon(Icons.dark_mode_outlined),
          label: Text(l10n.settingsThemeDark),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) {
        final choice = values.firstOrNull;
        if (choice != null) onSelected(choice);
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
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

Future<void> _onEncryptDatabaseToggle({
  required BuildContext context,
  required WidgetRef ref,
  required bool requested,
}) async {
  final current = ref.read(appSettingsProvider).encryptDatabase;
  if (requested == current) return;

  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAdaptiveConfirmDialog(
    context: context,
    title: Text(l10n.settingsEncryptChangeTitle),
    content: Text(l10n.settingsEncryptChangeBody),
    cancelLabel: l10n.cancel,
    confirmLabel: l10n.settingsEncryptChangeConfirm,
  );
  if (confirmed != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    final ok = await ref
        .read(appDatabaseProvider.notifier)
        .migrateEncryptionPreservingData(
          persistNewEncryptionPreference: () => ref
              .read(appSettingsProvider.notifier)
              .setEncryptDatabase(requested),
          setEncryptionPreference: (encrypt) => ref
              .read(appSettingsProvider.notifier)
              .setEncryptDatabase(encrypt),
          previousEncryption: current,
        );
    await ref.read(itemsProvider.notifier).reloadFromDatabase();
    await ref.read(participantsProvider.notifier).reloadFromDatabase();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsEncryptMigrationRolledBack)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsEncryptChangeError)));
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// When true (e.g. [NavigationRail] on large screens), no [AppBar]—the shell
  /// provides navigation.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final selected = _languageChoice(settings);

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = (constraints.maxWidth - 32).clamp(240.0, 560.0);
        return ListView(
          children: [
            if (embedded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  l10n.settings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.settingsV0ManagePreferences,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
            const SettingsV0ActivityInsightsCard(),
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
            if (_useExpressiveComponents(context))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LanguageChoiceSegment(
                  selected: selected,
                  onSelected: (choice) {
                    switch (choice) {
                      case _LanguageChoice.device:
                        notifier.setFollowDeviceLanguage();
                        break;
                      case _LanguageChoice.english:
                        notifier.setExplicitLanguage('en');
                        break;
                      case _LanguageChoice.indonesian:
                        notifier.setExplicitLanguage('id');
                        break;
                    }
                  },
                ),
              )
            else ...[
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
            ],
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsAppearance,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.settingsAppearanceSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            if (_useExpressiveComponents(context))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ThemeChoiceSegment(
                  selected: _themeChoice(settings),
                  onSelected: (choice) {
                    notifier.setThemeMode(
                      switch (choice) {
                        _ThemeChoice.light => ThemeMode.light,
                        _ThemeChoice.dark => ThemeMode.dark,
                        _ThemeChoice.system => ThemeMode.system,
                      },
                    );
                  },
                ),
              )
            else ...[
              _ThemeTile(
                label: _themeFollowDeviceLabel(l10n),
                selected: _themeChoice(settings) == _ThemeChoice.system,
                onTap: () => notifier.setThemeMode(ThemeMode.system),
              ),
              _ThemeTile(
                label: l10n.settingsThemeLight,
                selected: _themeChoice(settings) == _ThemeChoice.light,
                onTap: () => notifier.setThemeMode(ThemeMode.light),
              ),
              _ThemeTile(
                label: l10n.settingsThemeDark,
                selected: _themeChoice(settings) == _ThemeChoice.dark,
                onTap: () => notifier.setThemeMode(ThemeMode.dark),
              ),
            ],
            if (defaultTargetPlatform == TargetPlatform.android &&
                ref.watch(dynamicColorSupportedProvider))
              SwitchListTile.adaptive(
                value: settings.useDynamicColor,
                onChanged: (enabled) => notifier.setUseDynamicColor(enabled),
                title: Text(l10n.settingsMaterialYou),
                subtitle: Text(
                  l10n.settingsMaterialYouSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.settingsDefaultCurrencyRecordingNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownMenu<String>(
                key: ValueKey(settings.defaultCurrencyCode),
                width: menuWidth,
                initialSelection: settings.defaultCurrencyCode,
                label: Text(l10n.currencyLabel),
                dropdownMenuEntries: [
                  for (final code in kSupportedCurrencyCodes)
                    DropdownMenuEntry(
                      value: code,
                      label: currencyMenuLabel(code),
                    ),
                ],
                onSelected: (code) async {
                  if (code == null) return;
                  await notifier.setDefaultCurrency(code);
                  await ref.read(itemsProvider.notifier).reloadFromDatabase();
                },
              ),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsDataPrivacy,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SwitchListTile.adaptive(
              value: settings.encryptDatabase,
              onChanged: (enabled) => _onEncryptDatabaseToggle(
                context: context,
                ref: ref,
                requested: enabled,
              ),
              title: Text(l10n.settingsEncryptDatabase),
              subtitle: Text(
                l10n.settingsEncryptDatabaseSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsBackup,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _useExpressiveComponents(context)
                  ? MenuAnchor(
                      menuChildren: [
                        MenuItemButton(
                          leadingIcon: const Icon(Icons.settings_backup_restore),
                          onPressed: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const BackupScreen(),
                              ),
                            );
                          },
                          child: Text(l10n.settingsBackupManualTitle),
                        ),
                      ],
                      builder: (ctx, controller, _) => Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.upload_file_outlined),
                              label: Text(l10n.settingsBackupExport),
                              style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(20),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const BackupScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: l10n.settingsBackupManualTitle,
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(l10n.settingsBackupExport),
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const BackupScreen(),
                          ),
                        );
                      },
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(l10n.settingsBackupManualTitle),
              subtitle: Text(
                l10n.settingsBackupEntrySubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
                );
              },
            ),
          ],
        );
      },
    );

    if (embedded) {
      return body;
    }
    if (hostPlatformIsApple()) {
      return CupertinoPageScaffold(
        navigationBar: splitBaeCupertinoNavigationBar(
          context: context,
          title: l10n.settings,
        ),
        child: SafeArea(
          child: _AppleLiquidSettingsBody(
            settings: settings,
            selected: selected,
            notifier: notifier,
            onExport: () {
              Navigator.of(context).push<void>(
                CupertinoPageRoute<void>(
                  builder: (_) => const BackupScreen(),
                ),
              );
            },
            onReloadDraftItems: () =>
                ref.read(itemsProvider.notifier).reloadFromDatabase(),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: body,
    );
  }
}

class _AppleLiquidSettingsBody extends StatelessWidget {
  const _AppleLiquidSettingsBody({
    required this.settings,
    required this.selected,
    required this.notifier,
    required this.onExport,
    required this.onReloadDraftItems,
  });

  final AppSettings settings;
  final _LanguageChoice selected;
  final AppSettingsNotifier notifier;
  final VoidCallback onExport;
  final Future<void> Function() onReloadDraftItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final base = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.66)
        : CupertinoColors.systemBackground
              .resolveFrom(context)
              .withValues(alpha: 0.7);

    Widget glassSection({required List<Widget> children}) {
      final section = DecoratedBox(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: CupertinoColors.separator
                .resolveFrom(context)
                .withValues(alpha: 0.35),
          ),
          boxShadow: reduceMotion
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(children: children),
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: reduceMotion
            ? section
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: section,
              ),
      );
    }

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      );
    }

    Widget divider() => DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator
                .resolveFrom(context)
                .withValues(alpha: 0.3),
          ),
        ),
      ),
      child: const SizedBox(height: 0),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const SettingsV0ActivityInsightsCard(),
        sectionTitle(l10n.settingsLanguage),
        glassSection(
          children: [
            CupertinoListTile(
              title: Text(l10n.languageDevice),
              trailing: selected == _LanguageChoice.device
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: notifier.setFollowDeviceLanguage,
            ),
            divider(),
            CupertinoListTile(
              title: Text(l10n.languageEnglish),
              trailing: selected == _LanguageChoice.english
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: () => notifier.setExplicitLanguage('en'),
            ),
            divider(),
            CupertinoListTile(
              title: Text(l10n.languageIndonesian),
              trailing: selected == _LanguageChoice.indonesian
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: () => notifier.setExplicitLanguage('id'),
            ),
          ],
        ),
        sectionTitle(l10n.settingsAppearance),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.settingsAppearanceSubtitle,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
            ),
          ),
        ),
        glassSection(
          children: [
            CupertinoListTile(
              title: Text(_themeFollowDeviceLabel(l10n)),
              trailing: _themeChoice(settings) == _ThemeChoice.system
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: () => notifier.setThemeMode(ThemeMode.system),
            ),
            divider(),
            CupertinoListTile(
              title: Text(l10n.settingsThemeLight),
              trailing: _themeChoice(settings) == _ThemeChoice.light
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: () => notifier.setThemeMode(ThemeMode.light),
            ),
            divider(),
            CupertinoListTile(
              title: Text(l10n.settingsThemeDark),
              trailing: _themeChoice(settings) == _ThemeChoice.dark
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: () => notifier.setThemeMode(ThemeMode.dark),
            ),
          ],
        ),
        sectionTitle(l10n.settingsDefaultCurrency),
        glassSection(
          children: [
            CupertinoListTile(
              title: Text(l10n.settingsDefaultCurrencySubtitle),
            ),
            divider(),
            for (final code in kSupportedCurrencyCodes) ...[
              CupertinoListTile(
                title: Text(currencyMenuLabel(code)),
                trailing: settings.defaultCurrencyCode == code
                    ? const Icon(CupertinoIcons.check_mark)
                    : null,
                onTap: () async {
                  await notifier.setDefaultCurrency(code);
                  await onReloadDraftItems();
                },
              ),
              if (code != kSupportedCurrencyCodes.last) divider(),
            ],
          ],
        ),
        sectionTitle(l10n.settingsBackup),
        glassSection(
          children: [
            CupertinoListTile.notched(
              title: Text(l10n.settingsBackupExport),
              subtitle: Text(l10n.settingsBackupEntrySubtitle),
              leading: const Icon(CupertinoIcons.square_arrow_up),
              onTap: onExport,
            ),
            divider(),
            CupertinoListTile.notched(
              title: Text(l10n.settingsBackupManualTitle),
              subtitle: Text(l10n.settingsBackupEntrySubtitle),
              leading: const Icon(CupertinoIcons.tray_full),
              trailing: const CupertinoListTileChevron(),
              onTap: () {
                Navigator.of(context).push<void>(
                  CupertinoPageRoute<void>(
                    builder: (_) => const BackupScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
