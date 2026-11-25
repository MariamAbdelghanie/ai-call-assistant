import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../main.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
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

    return AppHeaderScaffold(
      title: strings.t('settingsTitle'),
      subtitle: strings.t('settingsSubtitle'),
      // Hesap karti bandin uzerine biniyor ama kaydirma listesinin
      // disinda duruyor; liste kaydiginda bandin altindan gecmiyor.
      overlapChild: user == null
          ? null
          : _ProfileCard(
              name: auth.displayName,
              email: user.email ?? '',
              photoUrl: auth.photoUrl,
            ),
      overlap: 34,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
        children: [
          SettingsGroup(
            title: strings.t('serverSection'),
            rows: [
              SettingsRow(
                icon: Icons.dns_outlined,
                label: strings.t('serverUrl'),
                value: state.serverUrl,
                onTap: () => _openServerSheet(context, state),
              ),
              SettingsRow(
                icon: state.isDemo
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_rounded,
                label: strings.t('apiToken'),
                value: state.isDemo
                    ? strings.t('offlineDemo')
                    : strings.t('connected'),
                valueColor: state.isDemo ? tokens.pending : tokens.success,
                onTap: () => _openServerSheet(context, state),
              ),
            ],
          ),

          SettingsGroup(
            title: strings.t('assistantSection'),
            rows: [
              SettingsRow(
                icon: Icons.support_agent_rounded,
                label: strings.t('assistantEnabled'),
                trailing: Switch.adaptive(
                  value: state.config.enabled,
                  onChanged: (value) => _saveConfig(
                    context,
                    state,
                    state.config.copyWith(enabled: value),
                  ),
                ),
              ),
              SettingsRow(
                icon: Icons.graphic_eq_rounded,
                label: strings.t('voiceTitle'),
                value: state.config.realtimeVoice,
                onTap: () => _openVoiceSheet(context, state),
              ),
              SettingsRow(
                icon: Icons.schedule_rounded,
                label: strings.t('workHours'),
                value: '${state.config.workStart} - ${state.config.workEnd}',
              ),
            ],
          ),

          SettingsGroup(
            title: strings.t('appearance'),
            rows: [
              SettingsRow(
                icon: Icons.contrast_rounded,
                label: strings.t('appearance'),
                value: themeNames[state.themeMode],
                onTap: () => _openThemeSheet(context, state, themeNames),
              ),
              SettingsRow(
                icon: Icons.translate_rounded,
                label: strings.t('appLanguage'),
                value: languageNames[state.locale.languageCode],
                onTap: () => _openLanguageSheet(context, state, languageNames),
              ),
            ],
          ),

          SettingsGroup(
            title: strings.t('privacy'),
            rows: [
              SettingsRow(
                icon: Icons.delete_outline_rounded,
                label: strings.t('deleteAll'),
                danger: true,
                onTap: () => _confirmDeleteAll(context, state),
              ),
            ],
          ),

          // Cikis en altta ve gruplardan ayri: yanlislikla basilmasi zor
          // olsun diye hem uzakta hem farkli bicimde.
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.urgent,
                side: BorderSide(color: tokens.urgent.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
              ),
              onPressed: auth.isBusy ? null : () => _confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: Text(strings.t('signOut')),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
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

/// Turuncu bandin uzerine binen beyaz hesap karti.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    this.photoUrl,
  });

  final String name;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final initial =
        name.trim().isEmpty ? 'C' : name.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: tokens.glass,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: tokens.glassBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppPalette.indigoSoft,
                foregroundImage:
                    photoUrl == null ? null : NetworkImage(photoUrl!),
                child: Text(
                  initial,
                  style: context.text.headlineSmall?.copyWith(
                    color: AppPalette.indigo,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // Oturumun acik oldugunu gosteren nokta.
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: tokens.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.glass, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: tokens.muted),
            ),
          ],
        ],
      ),
    );
  }
}
