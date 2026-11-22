import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/soft_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _server;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _server.text = AppScope.of(context).serverUrl;
      _initialised = true;
    }
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return GlassScaffold(
      title: strings.t('settingsTitle'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          _Group(
            title: strings.t('serverSection'),
            children: [
              TextField(
                controller: _server,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: strings.t('serverUrl'),
                  hintText: strings.t('serverHint'),
                  prefixIcon: const SoftIcon(AppIcon.layers),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SoftIcon(
                    state.isDemo
                        ? AppIcon.cloudOff
                        : AppIcon.cloud,
                    size: 18,
                    color: state.isDemo
                        ? context.tokens.pending
                        : context.tokens.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.isDemo
                          ? strings.t('offlineDemo')
                          : strings.t('connected'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: state.isDemo
                            ? context.tokens.pending
                            : context.tokens.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await state.setServerUrl(_server.text);
                    messenger.showSnackBar(
                      SnackBar(content: Text(strings.t('saved'))),
                    );
                  },
                  icon: const SoftIcon(AppIcon.link, size: 18),
                  label: Text(strings.t('serverSave')),
                ),
              ),
            ],
          ),
          _Group(
            title: strings.t('assistantSection'),
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: state.config.enabled,
                title: Text(strings.t('assistantEnabled')),
                onChanged: (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await state.saveConfig(
                    state.config.copyWith(enabled: value),
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.t(ok ? 'saved' : 'loadError'),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              Text(strings.t('voiceTitle'), style: context.text.labelLarge),
              const SizedBox(height: 4),
              Text(
                strings.t('voiceHint'),
                style: context.text.bodySmall
                    ?.copyWith(color: context.tokens.muted),
              ),
              const SizedBox(height: 10),
              // Gemini Live'in hazir sesleri. Biri kotaya takilirsa
              // digerine gecmek icin buradan degistirilir.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final voice in const ['Kore', 'Puck', 'Charon', 'Fenrir'])
                    ChoiceChip(
                      label: Text(voice),
                      selected: state.config.realtimeVoice == voice,
                      onSelected: (_) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await state.saveConfig(
                          state.config.copyWith(
                            architecture: 'realtime',
                            realtimeVoice: voice,
                          ),
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.t(ok ? 'saved' : 'loadError'),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: AppIcon.clock,
                label: strings.t('workHours'),
                value: '${state.config.workStart} - ${state.config.workEnd}',
              ),
              _InfoRow(
                icon: AppIcon.wave,
                label: strings.t('voice'),
                value: state.config.activeVoice,
              ),
            ],
          ),
          _Group(
            title: strings.t('appearance'),
            children: [
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(strings.t('themeSystem')),
                    icon: const SoftIcon(AppIcon.auto, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(strings.t('themeLight')),
                    icon: const SoftIcon(AppIcon.sun, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(strings.t('themeDark')),
                    icon: const SoftIcon(AppIcon.moon, size: 18),
                  ),
                ],
                selected: {state.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (values) =>
                    state.setThemeMode(values.first),
              ),
              const SizedBox(height: 16),
              Text(
                strings.t('appLanguage'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in const <(String, String)>[
                    ('tr', 'Türkçe'),
                    ('ar', 'العربية'),
                    ('en', 'English'),
                  ])
                    ChoiceChip(
                      label: Text(entry.$2),
                      selected: state.locale.languageCode == entry.$1,
                      labelStyle: TextStyle(
                        color: state.locale.languageCode == entry.$1
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => state.setLocale(Locale(entry.$1)),
                    ),
                ],
              ),
            ],
          ),
          _Group(
            title: strings.t('privacy'),
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.tokens.urgent,
                    side: BorderSide(
                      color: context.tokens.urgent.withValues(alpha: 0.5),
                    ),
                  ),
                  onPressed: () => _confirmDeleteAll(context, state),
                  icon: const SoftIcon(AppIcon.trash, size: 18),
                  label: Text(strings.t('deleteAll')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.tokens.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: context.tokens.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final AppIcon icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SoftIcon(icon, size: 18, color: context.tokens.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
