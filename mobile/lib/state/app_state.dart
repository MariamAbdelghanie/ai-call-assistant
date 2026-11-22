import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_summary.dart';
import '../services/api_client.dart';

enum LoadStatus { idle, loading, ready, demo, offline }

/// Uygulamanin tek durum kaynagi: ayarlar, cagri listesi ve baglanti durumu.
class AppState extends ChangeNotifier {
  AppState(this._api);

  final ApiClient _api;
  SharedPreferences? _prefs;

  static const _kServer = 'server_url';
  static const _kLocale = 'locale';
  static const _kTheme = 'theme_mode';
  // Ornek (demo) kayitlarda silme islemi sunucuya gitmedigi icin, silinenlerin
  // kimlikleri cihazda saklanir; yoksa uygulama her acilista geri geliyordu.
  static const _kHidden = 'hidden_call_ids';
  // Son basarili cekimin kopyasi. Sunucuya ulasilamadiginda gercek kayitlarin
  // yerine ornek veri gosterilmesi, silinmis kayitlarin geri geldigi ve yeni
  // kayitlarin kayboldugu izlenimini veriyordu.
  static const _kCache = 'calls_cache';

  String serverUrl = '';
  Locale locale = const Locale('tr');
  // Tasarim koyu zemin icin kurgulandi; acik tema yine ayarlardan secilebilir.
  ThemeMode themeMode = ThemeMode.dark;

  LoadStatus status = LoadStatus.idle;
  String? errorMessage;
  List<CallSummary> calls = const <CallSummary>[];
  AssistantConfig config = AssistantConfig.fallback;
  Set<String> _hiddenIds = <String>{};

  bool get isDemo => status == LoadStatus.demo;
  bool get isOffline => status == LoadStatus.offline;

  /// Sunucu verisi gosterilmiyorsa true: silme gibi islemler guvenli degil.
  bool get isReadOnly => isDemo || isOffline;

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
    _hiddenIds = (_prefs?.getStringList(_kHidden) ?? const <String>[]).toSet();
    _restoreCache();
    final theme = _prefs?.getString(_kTheme);
    themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
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

  /// Sunucudan ceker.
  ///
  /// Ulasilamazsa son basarili kayitlar gosterilir. Ornek (demo) veriler
  /// yalnizca hic sunucu adresi girilmemisken, tanitim amaciyla gosterilir.
  Future<void> refresh() async {
    if (serverUrl.isEmpty) {
      // Sunucu adresi girilmemis: uydurma kayit gostermek yerine bos liste
      // ve adresi ayarlamayi soyleyen bir uyari gosterilir.
      calls = const <CallSummary>[];
      config = AssistantConfig.fallback;
      status = LoadStatus.offline;
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
      calls = _visible(fetched);
      config = fetchedConfig;
      status = LoadStatus.ready;
      await _saveCache(fetched);
    } catch (error) {
      errorMessage = error.toString();
      // Sunucu adresi girilmisse ornek veriye ASLA dusulmez: uydurma kayitlar
      // gercek kayit sanilip karisikliga yol aciyordu. Elimizde onbellek varsa
      // o gosterilir, yoksa liste bos kalir ve uyari seridi cikar.
      if (!_restoreCache()) {
        // Onbellek de yoksa liste bos kalsin; uydurma kayit gosterilmez.
        calls = const <CallSummary>[];
      }
      status = LoadStatus.offline;
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
    if (isOffline) {
      // Sunucuya ulasilamiyor: silme gerceklesmedigi icin listeyi geri al.
      calls = previous;
      notifyListeners();
      return false;
    }
    if (isDemo || serverUrl.isEmpty) {
      await _hide([call.callId]);
      return true;
    }
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
    if (isOffline) {
      calls = previous;
      notifyListeners();
      return false;
    }
    if (isDemo || serverUrl.isEmpty) {
      await _hide(toDelete.map((c) => c.callId));
      return true;
    }
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

  /// Son basarili cekimi cihaza yazar.
  Future<void> _saveCache(List<CallSummary> source) async {
    try {
      final payload =
          jsonEncode(source.map((c) => c.toJson()).toList(growable: false));
      await _prefs?.setString(_kCache, payload);
    } catch (_) {
      // Onbellek yazilamazsa uygulama calismaya devam eder.
    }
  }

  /// Onbellekteki kayitlari yukler. Kayit varsa true doner.
  bool _restoreCache() {
    final raw = _prefs?.getString(_kCache);
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) return false;
      calls = _visible(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(CallSummary.fromJson)
            .toList(growable: false),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cihazda saklanan silinmis kayitlari listeden cikarir.
  List<CallSummary> _visible(List<CallSummary> source) {
    if (_hiddenIds.isEmpty) return source;
    return source
        .where((c) => !_hiddenIds.contains(c.callId))
        .toList(growable: false);
  }

  Future<void> _hide(Iterable<String> ids) async {
    _hiddenIds = {..._hiddenIds, ...ids};
    await _prefs?.setStringList(_kHidden, _hiddenIds.toList());
  }

  /// Silinmis ornek kayitlari geri getirir (ayarlardan cagrilir).
  Future<void> restoreHidden() async {
    _hiddenIds = <String>{};
    await _prefs?.remove(_kHidden);
    await refresh();
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
