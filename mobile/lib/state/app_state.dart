import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_summary.dart';
import '../services/api_client.dart';

enum LoadStatus { idle, loading, ready, demo }

/// Uygulamanin tek durum kaynagi: ayarlar, cagri listesi ve baglanti durumu.
class AppState extends ChangeNotifier {
  AppState(this._api);

  final ApiClient _api;
  SharedPreferences? _prefs;

  static const _kServer = 'server_url';
  static const _kLocale = 'locale';
  static const _kTheme = 'theme_mode';

  String serverUrl = '';
  Locale locale = const Locale('tr');
  ThemeMode themeMode = ThemeMode.system;

  LoadStatus status = LoadStatus.idle;
  String? errorMessage;
  List<CallSummary> calls = const <CallSummary>[];
  AssistantConfig config = AssistantConfig.fallback;

  bool get isDemo => status == LoadStatus.demo;

  int get urgentCount => calls.where((c) => c.isUrgent).length;
  int get awaitingCount => calls.where((c) => c.awaitingCallback).length;
  List<CallSummary> get urgentCalls =>
      calls.where((c) => c.isUrgent).toList(growable: false);
  List<CallSummary> get appointments =>
      calls.where((c) => c.hasAppointment).toList(growable: false);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    serverUrl = _prefs?.getString(_kServer) ?? '';
    final code = _prefs?.getString(_kLocale);
    if (code != null && code.isNotEmpty) locale = Locale(code);
    final theme = _prefs?.getString(_kTheme);
    themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
    await refresh();
  }

  Future<void> setLocale(Locale value) async {
    locale = value;
    await _prefs?.setString(_kLocale, value.languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _prefs?.setString(
      _kTheme,
      switch (value) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
    notifyListeners();
  }

  Future<void> setServerUrl(String value) async {
    serverUrl = value.trim();
    await _prefs?.setString(_kServer, serverUrl);
    notifyListeners();
    await refresh();
  }

  /// Sunucudan ceker; ulasilamazsa ornek verilere duser ve bunu gorunur kilar.
  Future<void> refresh() async {
    if (serverUrl.isEmpty) {
      calls = DemoData.calls();
      config = AssistantConfig.fallback;
      status = LoadStatus.demo;
      errorMessage = null;
      notifyListeners();
      return;
    }

    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _api.fetchCalls(serverUrl);
      AssistantConfig fetchedConfig = config;
      try {
        fetchedConfig = await _api.fetchConfig(serverUrl);
      } catch (_) {
        // Ayarlar alinamazsa cagri listesi yine de gosterilir.
      }
      calls = fetched;
      config = fetchedConfig;
      status = LoadStatus.ready;
    } catch (error) {
      calls = DemoData.calls();
      config = AssistantConfig.fallback;
      status = LoadStatus.demo;
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<bool> toggleCalledBack(CallSummary call) async {
    final next = !call.calledBack;
    _replace(call.copyWith(calledBack: next));
    if (isDemo || serverUrl.isEmpty) return true;
    try {
      await _api.markCalledBack(serverUrl, call.callId, calledBack: next);
      return true;
    } catch (_) {
      _replace(call);
      return false;
    }
  }

  Future<bool> deleteCall(CallSummary call) async {
    final previous = calls;
    calls = calls.where((c) => c.callId != call.callId).toList(growable: false);
    notifyListeners();
    if (isDemo || serverUrl.isEmpty) return true;
    try {
      await _api.deleteCall(serverUrl, call.callId);
      return true;
    } catch (_) {
      calls = previous;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAll() async {
    final previous = calls;
    final toDelete = List<CallSummary>.from(calls);
    calls = const <CallSummary>[];
    notifyListeners();
    if (isDemo || serverUrl.isEmpty) return true;
    try {
      for (final call in toDelete) {
        await _api.deleteCall(serverUrl, call.callId);
      }
      return true;
    } catch (_) {
      calls = previous;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveConfig(AssistantConfig next) async {
    final previous = config;
    config = next;
    notifyListeners();
    if (isDemo || serverUrl.isEmpty) return true;
    try {
      await _api.saveConfig(serverUrl, next);
      return true;
    } catch (_) {
      config = previous;
      notifyListeners();
      return false;
    }
  }

  void _replace(CallSummary updated) {
    calls = calls
        .map((c) => c.callId == updated.callId ? updated : c)
        .toList(growable: false);
    notifyListeners();
  }
}

/// Alt agaclarin AppState'e ulasmasi icin basit bir tasiyici.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadi');
    return scope!.notifier!;
  }
}
