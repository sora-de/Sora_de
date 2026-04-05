import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sorade/data/firestore_sorade_repository.dart';
import 'package:sorade/firebase_options.dart';
import 'package:sorade/l10n/app_localizations.dart';
import 'package:sorade/screens/auth_screen.dart';
import 'package:sorade/screens/shell_screen.dart';
import 'package:sorade/screens/welcome_screen.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
    runApp(FirebaseInitErrorApp(message: e.toString()));
    return;
  }

  // Windows: Firestore + Storage still hit https://github.com/firebase/flutterfire/issues/11933
  // (native → Flutter on a background thread). Disabling persistence here cuts some callbacks.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    try {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    } catch (e) {
      debugPrint('Firestore settings (Windows): $e');
    }
  }

  runApp(SoradeApp(prefs: prefs));
}

class FirebaseInitErrorApp extends StatelessWidget {
  const FirebaseInitErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Firebase could not start',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Run flutterfire configure and add a Windows (or web) app in the Firebase console, then rebuild.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
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

class SoradeApp extends StatelessWidget {
  const SoradeApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'Sora de',
      theme: buildSoraDeTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final data = MediaQuery.of(context);
        final scaled = data.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 2.4,
        );
        return MediaQuery(
          data: data.copyWith(textScaler: scaled),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snap.data;
          if (user == null) {
            return const AuthScreen();
          }
          return ChangeNotifierProvider(
            key: ValueKey(user.uid),
            create: (_) => SoradeController(
              FirestoreSoradeRepository(uid: user.uid),
            ),
            child: _WelcomeGate(prefs: prefs),
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _WelcomeGate extends StatefulWidget {
  const _WelcomeGate({required this.prefs});

  final SharedPreferences prefs;

  @override
  State<_WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<_WelcomeGate> {
  late bool _showWelcome = widget.prefs.getBool('welcome_ok') != true;

  Future<void> _finishWelcome() async {
    await widget.prefs.setBool('welcome_ok', true);
    if (mounted) setState(() => _showWelcome = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showWelcome) return const ShellScreen();
    return WelcomeScreen(onContinue: _finishWelcome);
  }
}
