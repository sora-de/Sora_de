import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:sorade/core/brand_colors.dart';
import 'package:sorade/screens/how_to_use_screen.dart';
import 'package:sorade/services/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _passwordMessage;
  bool _passwordSuccess = false;

  AppVersionSnapshot? _versionSnap;
  bool _versionLoading = true;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _refreshVersion();
  }

  Future<void> _refreshVersion() async {
    setState(() => _versionLoading = true);
    final snap = await AppUpdateService.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _versionSnap = snap;
      _versionLoading = false;
    });
  }

  Future<void> _openDownloadUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the download link.')),
      );
    }
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? v) {
    if ((v ?? '').length < 6) return 'At least 6 characters';
    return null;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final newPw = _newPassword.text;
    if (newPw != _confirmPassword.text) {
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = 'New password and confirmation do not match.';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = 'Not signed in with email/password.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _passwordMessage = null;
      _passwordSuccess = false;
    });

    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: _currentPassword.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPw);
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) {
        setState(() {
          _passwordSuccess = true;
          _passwordMessage = 'Password updated.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = _mapPasswordError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapPasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'New password is too weak. Use a stronger one.';
      case 'requires-recent-login':
        return 'For security, sign out and sign in again, then change your password.';
      default:
        return e.message ?? e.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BrandColors.primaryGreen,
                ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snap) {
              final user = snap.data ?? FirebaseAuth.instance.currentUser;
              if (user == null) {
                return const Card(
                  child: ListTile(
                    title: Text('Not signed in'),
                  ),
                );
              }
              final email = user.email ?? '—';
              final verified = user.emailVerified;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Icon(Icons.person, color: cs.onPrimaryContainer),
                        ),
                        title: const Text('Email'),
                        subtitle: SelectableText(
                          email,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            verified ? Icons.verified_outlined : Icons.mark_email_unread_outlined,
                            size: 20,
                            color: verified ? cs.primary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              verified ? 'Email verified' : 'Email not verified',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (user.uid.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'User ID',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          user.uid,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.menu_book_outlined, color: cs.onPrimaryContainer),
              ),
              title: const Text('How to use the app'),
              subtitle: Text(
                'Daily flow, tabs, orders, money & reports',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const HowToUseScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'App update',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BrandColors.primaryGreen,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _isAndroid
                ? 'When you publish a new APK, raise the build number in Firebase (app_config/android) so users see an update here.'
                : 'Version info below. In-app APK updates apply on Android.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _versionLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _versionSnap == null
                      ? const ListTile(
                          title: Text('Could not load version'),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: cs.primaryContainer,
                                child: Icon(
                                  Icons.system_update_outlined,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              title: const Text('This device'),
                              subtitle: Text(_versionSnap!.currentLabel),
                              trailing: IconButton(
                                tooltip: 'Check again',
                                icon: const Icon(Icons.refresh),
                                onPressed: _refreshVersion,
                              ),
                            ),
                            if (_versionSnap!.errorMessage != null) ...[
                              Text(
                                _versionSnap!.errorMessage!,
                                style: TextStyle(
                                  color: cs.error,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_isAndroid &&
                                _versionSnap!.hasRemote &&
                                _versionSnap!.updateAvailable) ...[
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.new_releases_outlined,
                                  color: BrandColors.primaryPink,
                                ),
                                title: const Text('Update available'),
                                subtitle: Text(
                                  _versionSnap!.remote!.versionLabel != null
                                      ? 'Latest: ${_versionSnap!.remote!.versionLabel} (build ${_versionSnap!.remote!.latestBuildNumber})'
                                      : 'Build ${_versionSnap!.remote!.latestBuildNumber} is available',
                                ),
                              ),
                              if (_versionSnap!.remote!.releaseNotes != null &&
                                  _versionSnap!.remote!.releaseNotes!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    _versionSnap!.remote!.releaseNotes!.trim(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                              FilledButton.icon(
                                onPressed: () => _openDownloadUrl(
                                  _versionSnap!.remote!.downloadUrl,
                                ),
                                icon: const Icon(Icons.download_outlined),
                                label: const Text('Download update'),
                              ),
                            ] else if (_isAndroid && _versionSnap!.hasRemote) ...[
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.check_circle_outline, color: cs.primary),
                                title: const Text('You’re on the latest version'),
                              ),
                            ] else if (_isAndroid) ...[
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                                title: const Text('No update info yet'),
                                subtitle: Text(
                                  'Add Firestore document app_config/android with latestBuildNumber and downloadUrl.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.rocket_launch_outlined, color: cs.primary),
              title: Text(
                'Publishing an Android update',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              subtitle: Text(
                'Build APK, HTTPS link, Firestore, user install',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SelectableText(
                    '1. Build\n'
                    'Run: flutter build apk --release\n'
                    'APK: build/app/outputs/flutter-apk/app-release.apk\n\n'
                    '2. Host the file (free options)\n'
                    '• GitHub: create a Release on your repo and attach the .apk; copy the direct download link.\n'
                    '• Firebase Storage: upload the file and use a public download URL.\n'
                    '• Any HTTPS URL that starts the .apk download when opened in a browser.\n\n'
                    '3. Point the app at it\n'
                    'In Firestore, collection app_config, document android:\n'
                    '• latestBuildNumber (number) — must be greater than the installed build (pubspec version after +, e.g. 1.0.1+3 → use 3 or higher).\n'
                    '• downloadUrl (string) — the HTTPS link from step 2.\n'
                    'Optional: versionLabel, releaseNotes.\n'
                    'Deploy firestore.rules so signed-in users can read app_config.\n\n'
                    '4. First-time install / updates from the browser\n'
                    'Android may block installs until the user allows “Install unknown apps” (or “Install apps from this source”) for the browser or Files app they use. After downloading, open the APK from notifications or Downloads and tap Install.\n\n'
                    '5. Automate with GitHub Actions (optional)\n'
                    'This repo includes .github/workflows/android_release.yml. Bump version in pubspec.yaml (e.g. 1.0.2+8), commit, then either run the workflow manually (Actions tab) or push a git tag that matches: for 1.0.2+8 use tag v1.0.2-8. The workflow builds the APK, creates a GitHub Release with sorade-android.apk, and can update Firestore if you add the secret FIREBASE_SERVICE_ACCOUNT_JSON (Firebase service account with Firestore access). Enable Actions workflow “Read and write” permissions in the repo settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: cs.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Change password',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BrandColors.primaryGreen,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your current password, then choose a new one.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _currentPassword,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateNewPassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateNewPassword,
                    ),
                    if (_passwordMessage != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(
                        _passwordMessage!,
                        style: TextStyle(
                          color: _passwordSuccess ? cs.primary : cs.error,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _changePassword,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
