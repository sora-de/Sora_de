import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Free Android distribution (no Play Store fee): build `flutter build apk --release`,
/// upload the APK to **GitHub Releases**, **Firebase Storage** (public URL), or any
/// HTTPS host. In Firestore, create document `app_config/android` (see [fetchAndroidRelease])
/// with the latest build number and download URL. Bump `version:` in [pubspec.yaml]
/// (e.g. `1.0.1+2` → build number `2`) for each release, then match `latestBuildNumber`
/// in Firestore.
class AppRemoteRelease {
  const AppRemoteRelease({
    required this.latestBuildNumber,
    this.versionLabel,
    required this.downloadUrl,
    this.releaseNotes,
  });

  final int latestBuildNumber;
  final String? versionLabel;
  final String downloadUrl;
  final String? releaseNotes;
}

class AppVersionSnapshot {
  AppVersionSnapshot({
    required this.packageInfo,
    this.remote,
    this.errorMessage,
  });

  final PackageInfo packageInfo;
  final AppRemoteRelease? remote;
  final String? errorMessage;

  int get currentBuild => int.tryParse(packageInfo.buildNumber) ?? 0;

  bool get hasRemote => remote != null;

  bool get updateAvailable =>
      remote != null && remote!.latestBuildNumber > currentBuild;

  String get currentLabel =>
      '${packageInfo.version} (${packageInfo.buildNumber})';
}

class AppUpdateService {
  AppUpdateService._();

  static final _doc = FirebaseFirestore.instance.doc('app_config/android');

  /// Reads `app_config/android`. Expected fields:
  /// - `latestBuildNumber` (int) — must exceed local [PackageInfo.buildNumber] to prompt update
  /// - `downloadUrl` (string) — direct HTTPS link to the `.apk` file
  /// - `versionLabel` (string, optional) — e.g. "1.0.2" for display
  /// - `releaseNotes` (string, optional)
  static Future<AppRemoteRelease?> fetchAndroidRelease() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final build = data['latestBuildNumber'];
    final url = data['downloadUrl'] as String?;
    if (build is! num || url == null || url.isEmpty) return null;
    return AppRemoteRelease(
      latestBuildNumber: build.toInt(),
      versionLabel: data['versionLabel'] as String?,
      downloadUrl: url.trim(),
      releaseNotes: data['releaseNotes'] as String?,
    );
  }

  static Future<AppVersionSnapshot> loadSnapshot() async {
    final packageInfo = await PackageInfo.fromPlatform();
    try {
      final remote = await fetchAndroidRelease();
      return AppVersionSnapshot(packageInfo: packageInfo, remote: remote);
    } catch (e) {
      return AppVersionSnapshot(
        packageInfo: packageInfo,
        errorMessage: e.toString(),
      );
    }
  }
}
