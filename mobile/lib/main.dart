import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/api_client.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(ApiClient());
  state.load();
  runApp(CallAssistantApp(state: state));
}

class CallAssistantApp extends StatefulWidget {
  const CallAssistantApp({super.key, required this.state});

  final AppState state;

  @override
  State<CallAssistantApp> createState() => _CallAssistantAppState();
}

class _CallAssistantAppState extends State<CallAssistantApp> {
  bool _welcomed = false;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => AppStrings.of(context).t('appTitle'),
            title: 'Cagri Asistani',
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
            home: _welcomed
                ? const HomeShell()
                : WelcomeScreen(
                    onStart: () => setState(() => _welcomed = true),
                  ),
          );
        },
      ),
    );
  }
}
