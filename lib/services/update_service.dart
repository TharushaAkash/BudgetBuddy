import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.isUpdateAvailable,
    required this.latestVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos/TharushaAkash/BudgetBuddy/releases/latest';
  static const String _sourceforgeUrl = 'https://sourceforge.net/projects/budget-buddy';

  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. '1.0.0'

      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String tagName = data['tag_name'] ?? ''; // e.g. 'v1.0.1' or '1.0.1'
        final String releaseTitle = data['name'] ?? 'New Update Available';
        final String releaseNotes = data['body'] ?? '';

        // Strip 'v' prefix if present
        final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          return UpdateInfo(
            isUpdateAvailable: true,
            latestVersion: latestVersion,
            releaseTitle: releaseTitle,
            releaseNotes: releaseNotes,
            downloadUrl: _sourceforgeUrl,
          );
        }
      }
    } catch (e) {
      // Silently fail if unable to check for updates (e.g. no internet)
      print('Update check failed: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
