import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/live_call_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/voice_orb.dart';
import '../widgets/soft_icon.dart';

/// Asistani uygulamadan arayip mimariyi canli denemek icin ekran.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final LiveCallService _call = LiveCallService();

  @override
  void dispose() {
    _call.dispose();
    super.dispose();
  }

  String _duration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _statusText(LiveCallService call, AppStrings strings) {
    return switch (call.phase) {
      CallPhase.idle => strings.t('callIdle'),
      CallPhase.connecting => strings.t('callConnecting'),
      CallPhase.ending => strings.t('callEnding'),
      CallPhase.failed => strings.t('callFailed'),
      CallPhase.connected => call.assistantSpeaking
          ? strings.t('callAssistantSpeaking')
          : strings.t('callListening'),
    };
  }

  String _errorText(String? code, AppStrings strings) {
    return switch (code) {
      'server_missing' => strings.t('callNoServer'),
      'mic_denied' => strings.t('callMicDenied'),
      _ => strings.t('callGenericError'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    return GlassScaffold(
      title: strings.t('tabCall'),
      body: ListenableBuilder(
        listenable: _call,
        builder: (context, _) {
          final active = _call.isActive;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  _ConnectionPill(
                    connected: !state.isDemo,
                    label: state.isDemo
                        ? strings.t('offlineDemo')
                        : state.serverUrl,
                    onTap: widget.onOpenSettings,
                  ),
                  const Spacer(),
                  VoiceOrb(
                    size: 280,
                    speaking: _call.assistantSpeaking,
                    listening: active && _call.micEnabled &&
                        !_call.assistantSpeaking,
                    dim: !active,
                  ),
                  const SizedBox(height: 22),
                  OrbWaveform(active: active),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: AppTheme.normal,
                    child: Text(
                      _statusText(_call, strings),
                      key: ValueKey(_statusText(_call, strings)),
                      style: context.text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    active
                        ? _duration(_call.elapsed)
                        : strings.t('callHint'),
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(
                      color: tokens.muted,
                      fontFeatures: active
                          ? const [FontFeature.tabularFigures()]
                          : null,
                    ),
                  ),
                  if (_call.phase == CallPhase.failed) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.urgentSoft,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: tokens.urgent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          SoftIcon(AppIcon.urgent,
                              size: 18, color: tokens.urgent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _errorText(_call.errorMessage, strings),
                                  style: context.text.bodySmall
                                      ?.copyWith(color: tokens.urgent),
                                ),
                                if (_call.errorMessage != null &&
                                    _call.errorMessage != 'server_missing' &&
                                    _call.errorMessage != 'mic_denied') ...[
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    _call.errorMessage!,
                                    maxLines: 4,
                                    style: context.text.labelSmall?.copyWith(
                                      color: tokens.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (active)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundAction(
                          icon: _call.micEnabled
                              ? AppIcon.mic
                              : AppIcon.micOff,
                          label: strings.t(
                            _call.micEnabled ? 'callMute' : 'callUnmute',
                          ),
                          background: tokens.glass,
                          foreground: context.scheme.onSurface,
                          border: tokens.glassBorder,
                          onTap: _call.toggleMic,
                        ),
                        const SizedBox(width: 28),
                        _RoundAction(
                          icon: AppIcon.phoneEnd,
                          label: strings.t('callHangUp'),
                          background: tokens.urgent,
                          foreground: Colors.white,
                          size: 76,
                          onTap: _call.hangUp,
                        ),
                      ],
                    )
                  else
                    _CallButton(
                      busy: _call.isBusy,
                      label: strings.t('callStart'),
                      onTap: _call.isBusy
                          ? null
                          : () => _call.start(state.serverUrl),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({
    required this.connected,
    required this.label,
    required this.onTap,
  });

  final bool connected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = connected ? tokens.success : tokens.pending;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: tokens.glass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(
                    color: tokens.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.busy,
    required this.label,
    required this.onTap,
  });

  final bool busy;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: tokens.fourColorGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppPalette.sage.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SoftIcon(AppIcon.phone,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: context.text.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.border,
    this.size = 64,
  });

  final AppIcon icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: label,
          child: Material(
            color: background,
            shape: CircleBorder(
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: border!),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: size,
                height: size,
                child: SoftIcon(icon, color: foreground, size: size * 0.42),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: context.text.labelSmall
              ?.copyWith(color: context.tokens.muted),
        ),
      ],
    );
  }
}
