import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sorade/core/brand_colors.dart';
import 'package:sorade/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

class _ParsedAuthError {
  const _ParsedAuthError(this.short, [this.detail]);
  final String short;
  final String? detail;
}

_ParsedAuthError _parseAuthError(FirebaseAuthException e) {
  debugPrint('FirebaseAuthException code=${e.code} message=${e.message}');
  if (e.code == 'email-already-in-use') {
    return const _ParsedAuthError(
      'This email is already registered. Try Sign in or Forgot password.',
    );
  }
  final msg = (e.message ?? '').trim();
  final code = e.code;
  final lower = '$code $msg'.toLowerCase();
  final looksInternal =
      lower.contains('internal') || code == 'unknown-error';

  if (defaultTargetPlatform == TargetPlatform.windows && looksInternal) {
    return _ParsedAuthError(
      "Couldn't reach Firebase Auth on Windows ($code).",
      'This often happens when the Browser API key in Google Cloud is limited '
      'to HTTP referrers. Desktop apps do not send a web referrer, so Identity '
      'Toolkit calls fail.\n\n'
      '1. Tap Open API key settings below.\n'
      '2. Open your Web/Browser key → Application restrictions → None '
      '(for a quick test).\n'
      '3. Save, wait a minute, try again.\n\n'
      'Alternative: run the app in Chrome — `flutter run -d chrome` — then sign in there.',
    );
  }

  final head = msg.isNotEmpty ? '$msg [$code]' : code;
  return _ParsedAuthError(head);
}

/// Retries [op] when Windows returns a flaky [unknown-error] from the native Auth SDK.
Future<T> _runAuthWithRetries<T>(Future<T> Function() op) async {
  const maxAttempts = 3;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await op();
    } on FirebaseAuthException catch (e) {
      final canRetry = attempt < maxAttempts - 1 &&
          defaultTargetPlatform == TargetPlatform.windows &&
          e.code == 'unknown-error';
      debugPrint('FirebaseAuth attempt ${attempt + 1}/$maxAttempts: ${e.code}');
      if (!canRetry) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
    }
  }
  throw StateError('_runAuthWithRetries: no result');
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _registerInFlight = false;
  String? _errorShort;
  String? _errorDetail;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _openApiKeySettings() async {
    final id = DefaultFirebaseOptions.currentPlatform.projectId;
    final uri = Uri.parse(
      'https://console.cloud.google.com/apis/credentials?project=$id',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open browser. Go to Google Cloud → Credentials → project $id')),
      );
    }
  }

  bool _validateOrHint() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check email and password (6+ characters).')),
      );
    }
    return ok;
  }

  Future<void> _sendPasswordReset() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email above first.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    }
  }

  Future<void> _signIn() async {
    if (!_validateOrHint()) return;
    setState(() {
      _busy = true;
      _registerInFlight = false;
      _errorShort = null;
      _errorDetail = null;
    });
    try {
      await _runAuthWithRetries(
        () => FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            ),
      );
    } on FirebaseAuthException catch (e) {
      final p = _parseAuthError(e);
      setState(() {
        _errorShort = p.short;
        _errorDetail = p.detail;
      });
    } catch (e, st) {
      debugPrint('Sign-in error: $e\n$st');
      setState(() => _errorShort = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _registerInFlight = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_validateOrHint()) return;
    setState(() {
      _busy = true;
      _registerInFlight = true;
      _errorShort = null;
      _errorDetail = null;
    });
    try {
      final email = _email.text.trim();
      try {
        // When "email enumeration protection" is on in Firebase, this may fail or
        // return empty; we still catch email-already-in-use on create.
        final methods = await FirebaseAuth.instance
            // ignore: deprecated_member_use
            .fetchSignInMethodsForEmail(email);
        if (methods.contains(EmailAuthProvider.EMAIL_PASSWORD_SIGN_IN_METHOD)) {
          if (mounted) {
            setState(() {
              _errorShort =
                  'This email is already registered. Try Sign in or Forgot password.';
              _errorDetail = null;
            });
          }
          return;
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('fetchSignInMethodsForEmail skipped: ${e.code}');
      }

      await _runAuthWithRetries(
        () => FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: _password.text,
            ),
      );
    } on FirebaseAuthException catch (e) {
      final p = _parseAuthError(e);
      setState(() {
        _errorShort = p.short;
        _errorDetail = p.detail;
      });
    } catch (e, st) {
      debugPrint('Register error: $e\n$st');
      setState(() => _errorShort = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _registerInFlight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sora de',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: BrandColors.primaryGreen,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with your account. Data syncs to your Firebase project (Spark plan is fine).',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Enter email';
                        if (!t.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if ((v ?? '').length < 6) {
                          return 'At least 6 characters';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _sendPasswordReset,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (_errorShort != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        _errorShort!,
                        style: TextStyle(
                          color: cs.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      if (_errorDetail != null) ...[
                        const SizedBox(height: 8),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Steps to fix',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(
                                _errorDetail!,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _busy ? null : _openApiKeySettings,
                              icon: const Icon(Icons.key, size: 18),
                              label: const Text('Open API key settings'),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _signIn,
                      child: _busy && !_registerInFlight
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : _register,
                      child: _busy && _registerInFlight
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
