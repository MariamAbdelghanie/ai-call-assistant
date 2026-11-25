import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Durum cubugu uygulamanin zeminiyle birlesir; ustte gri serit kalmaz.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final api = ApiClient();
  final auth = AuthService();
  // Her istekte guncel kimlik belirteci alinir; sunucu kullaniciyi
  // bundan tanir ve yalnizca ona ait kayitlari dondurur.
  api.idTokenProvider = auth.idToken;
  final state = AppState(api);
  state.load();
  auth.initialize();
  runApp(CallAssistantApp(state: state, auth: auth));
}

/// Oturum servisini alt agaca tasir (ornegin Ayarlar ekranindaki cikis dugmesi).
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService auth, required super.child})
      : super(notifier: auth);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope bulunamadi');
    return scope!.notifier!;
  }
}

class CallAssistantApp extends StatefulWidget {
  const CallAssistantApp({super.key, required this.state, required this.auth});

  final AppState state;
  final AuthService auth;

  @override
  State<CallAssistantApp> createState() => _CallAssistantAppState();
}

class _CallAssistantAppState extends State<CallAssistantApp> {
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    _lastUid = widget.auth.user?.uid;
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Kullanici degistiginde kayitlar da degisir: onceki hesabin listesi
  /// ekranda kalmasin diye yeniden cekilir.
  void _onAuthChanged() {
    final uid = widget.auth.user?.uid;
    if (uid == _lastUid) return;
    _lastUid = uid;
    widget.state.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: AuthScope(
        auth: widget.auth,
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.state, widget.auth]),
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) =>
                  AppStrings.of(context).t('appTitle'),
              title: 'CALLORA',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: widget.state.themeMode,
              locale: widget.state.locale,
              supportedLocales: AppStrings.supported,
              localizationsDelegates: const [
                AppStringsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: _home(),
            );
          },
        ),
      ),
    );
  }

  /// Acilis -> Giris -> Uygulama.
  ///
  /// Giris ekrani dogrudan acilir: arastirilan kalipta da oturum, araya
  /// fazladan bir tanitim adimi koymadan ilk ekranda istenir. Tanitim
  /// icerigi (ne yaptigimiz) giris ekraninin ustunde ozetlenir.
  Widget _home() {
    if (!widget.auth.isReady) return const _SplashScreen();
    if (!widget.auth.isSignedIn) return LoginScreen(auth: widget.auth);
    return const HomeShell();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}
