import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../main.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/home_parts.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/settings_row.dart';

/// Ayarlar ekrani.
///
/// Eskiden butun alanlar (sunucu adresi, belirtec, ses secimi, tema, dil)
/// ayni anda aciktı; sayfa uzun bir form yiginina donusuyordu. Simdi her
/// ayar tek satir: solda ikon, ortada adi, sagda su anki degeri. Degistirmek
/// icin satira dokunuluyor ve secenekler alttan acilan yaprakta cikiyor.
/// Boylece sayfa bir bakista okunuyor, derinlik istege bagli oluyor.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final auth = AuthScope.of(context);
    final user = auth.user;

    final languageNames = <String, String>{
      'tr': 'Türkçe',
      'ar': 'العربية',
      'en': 'English',
    };
    final themeNames = <ThemeMode, String>{
      ThemeMode.system: strings.t('themeSystem'),
      ThemeMode.light: strings.t('themeLight'),
      ThemeMode.dark: strings.t('themeDark'),
    };

    return PageScaffold(
      title: strings.t('settingsTitle'),
      children: [
        // Hesap: ayri bir basliga gerek yok, listenin ilk satiri.
        if (user != null) ...[
          CardGroup(
            dividerIndent: 0,
            children: [
              InkWell(
                onTap: () => _confirmSignOut(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppPalette.orangeSoft,
                        foregroundImage: auth.photoUrl == null
                            ? null
                            : NetworkImage(auth.photoUrl!),
                        child: Text(
                          auth.displayName.trim().isEmpty
                              ? 'C'
                              : auth.displayName
                                  .trim()
                                  .characters
                                  .first
                                  .toUpperCase(),
                          style: context.text.titleSmall?.copyWith(
                            color: AppPalette.accentDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall
                                  ?.copyWith(color: tokens.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: tokens.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],

        SectionLabel(strings.t('assistantSection')),
        CardGroup(
          dividerIndent: 48,
          children: [
            AppRow(
              icon: Icons.graphic_eq_rounded,
              title: strings.t('assistantEnabled'),
              subtitle: strings.t('assistantSubtitle'),
              trailing: Switch.adaptive(
                value: state.config.enabled,
                onChanged: (value) => _saveConfig(
                  context,
                  state,
                  state.config.copyWith(enabled: value),
                ),
              ),
            ),
            AppRow(
              icon: Icons.schedule_rounded,
              title: strings.t('workHours'),
              value: '${state.config.workStart} - ${state.config.workEnd}',
            ),
            AppRow(
              icon: Icons.mic_none_rounded,
              title: strings.t('voiceTitle'),
              value: state.config.realtimeVoice,
              onTap: () => _openVoiceSheet(context, state),
            ),
            // Ajanin konusabildigi diller: ayar degil, bilgi satiri.
            AppRow(
              icon: Icons.translate_rounded,
              title: strings.t('spokenLanguages'),
              subtitle: strings.t('spokenLanguagesValue'),
            ),
          ],
        ),
        const SizedBox(height: 22),

        SectionLabel(strings.t('sectionApp')),
        CardGroup(
          dividerIndent: 48,
          children: [
            AppRow(
              icon: Icons.contrast_rounded,
              title: strings.t('appearance'),
              value: themeNames[state.themeMode],
              onTap: () => _openThemeSheet(context, state, themeNames),
            ),
            AppRow(
              icon: Icons.language_rounded,
              title: strings.t('appLanguage'),
              value: languageNames[state.locale.languageCode],
              onTap: () => _openLanguageSheet(context, state, languageNames),
            ),
          ],
        ),
        const SizedBox(height: 22),

        SectionLabel(strings.t('sectionAdvanced')),
        CardGroup(
          dividerIndent: 48,
          children: [
            AppRow(
              icon: Icons.dns_outlined,
              title: strings.t('serverConnection'),
              subtitle: state.isDemo
                  ? strings.t('notConnected')
                  : '${strings.t('connected')} · ${state.serverUrl}',
              onTap: () => _openServerSheet(context, state),
            ),
            AppRow(
              icon: Icons.delete_outline_rounded,
              title: strings.t('deleteAll'),
              danger: true,
              onTap: () => _confirmDeleteAll(context, state),
            ),
            AppRow(
              icon: Icons.logout_rounded,
              title: strings.t('signOut'),
              danger: true,
              onTap: auth.isBusy ? null : () => _confirmSignOut(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveConfig(
    BuildContext context,
    AppState state,
    AssistantConfig config,
  ) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await state.saveConfig(config);
    messenger.showSnackBar(
      SnackBar(content: Text(strings.t(ok ? 'saved' : 'loadError'))),
    );
  }

  /// Sunucu adresi ve belirteci: ikisi birlikte kaydedildigi icin ayni
  /// yaprakta duruyor.
  Future<void> _openServerSheet(BuildContext context, AppState state) async {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final messenger = ScaffoldMessenger.of(context);
    final server = TextEditingController(text: state.serverUrl);
    final token = TextEditingController(text: state.apiToken);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.isDark ? AppPalette.darkSurface : Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 2,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.t('serverSection'),
              style: context.text.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: server,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: strings.t('serverUrl'),
                hintText: strings.t('serverHint'),
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: 14),
            // Sunucudaki API_TOKEN ile ayni olmali. Sunucu korumasizsa
            // bos birakildiginda da calisir.
            TextField(
              controller: token,
              autocorrect: false,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.t('apiToken'),
                helperText: strings.t('apiTokenHint'),
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  state.isDemo
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_done_rounded,
                  size: 18,
                  color: state.isDemo ? tokens.pending : tokens.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.isDemo
                        ? strings.t('offlineDemo')
                        : strings.t('connected'),
                    style: context.text.bodySmall?.copyWith(
                      color: state.isDemo ? tokens.pending : tokens.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  await state.setApiToken(token.text);
                  await state.setServerUrl(server.text);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  messenger.showSnackBar(
                    SnackBar(content: Text(strings.t('saved'))),
                  );
                },
                icon: const Icon(Icons.link_rounded, size: 18),
                label: Text(strings.t('serverSave')),
              ),
            ),
          ],
        ),
      ),
    );

    server.dispose();
    token.dispose();
  }

  /// Gemini Live'in hazir sesleri. Biri kotaya takilirsa digerine gecmek
  /// icin buradan degistirilir.
  Future<void> _openVoiceSheet(BuildContext context, AppState state) async {
    final strings = AppStrings.of(context);
    final choice = await showChoiceSheet<String>(
      context: context,
      title: strings.t('voiceTitle'),
      subtitle: strings.t('voiceHint'),
      selected: state.config.realtimeVoice,
      items: const [
        (value: 'Kore', label: 'Kore', hint: null, icon: Icons.graphic_eq),
        (value: 'Puck', label: 'Puck', hint: null, icon: Icons.graphic_eq),
        (value: 'Charon', label: 'Charon', hint: null, icon: Icons.graphic_eq),
        (value: 'Fenrir', label: 'Fenrir', hint: null, icon: Icons.graphic_eq),
      ],
    );
    if (choice == null || !context.mounted) return;
    await _saveConfig(
      context,
      state,
      state.config.copyWith(architecture: 'realtime', realtimeVoice: choice),
    );
  }

  Future<void> _openThemeSheet(
    BuildContext context,
    AppState state,
    Map<ThemeMode, String> names,
  ) async {
    final strings = AppStrings.of(context);
    final choice = await showChoiceSheet<ThemeMode>(
      context: context,
      title: strings.t('appearance'),
      selected: state.themeMode,
      items: [
        (
          value: ThemeMode.system,
          label: names[ThemeMode.system]!,
          hint: null,
          icon: Icons.brightness_auto_rounded
        ),
        (
          value: ThemeMode.light,
          label: names[ThemeMode.light]!,
          hint: null,
          icon: Icons.light_mode_rounded
        ),
        (
          value: ThemeMode.dark,
          label: names[ThemeMode.dark]!,
          hint: null,
          icon: Icons.dark_mode_rounded
        ),
      ],
    );
    if (choice == null) return;
    state.setThemeMode(choice);
  }

  Future<void> _openLanguageSheet(
    BuildContext context,
    AppState state,
    Map<String, String> names,
  ) async {
    final strings = AppStrings.of(context);
    final choice = await showChoiceSheet<String>(
      context: context,
      title: strings.t('appLanguage'),
      selected: state.locale.languageCode,
      items: [
        for (final entry in names.entries)
          (
            value: entry.key,
            label: entry.value,
            hint: null,
            icon: Icons.translate_rounded
          ),
      ],
    );
    if (choice == null) return;
    state.setLocale(Locale(choice));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final strings = AppStrings.of(context);
    final auth = AuthScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(strings.t('signOutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.t('signOut')),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.signOut();
  }

  Future<void> _confirmDeleteAll(BuildContext context, AppState state) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('deleteAll')),
        content: Text(strings.t('deleteAllBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await state.deleteAll();
    messenger.showSnackBar(
      SnackBar(content: Text(strings.t(ok ? 'allDeleted' : 'loadError'))),
    );
  }
}
