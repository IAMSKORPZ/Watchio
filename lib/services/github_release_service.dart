import 'dart:convert';

import 'package:http/http.dart' as http;

enum UpdateChannel { stable, beta, development }

class GitHubRelease {
  final String version;
  final String releaseNotes;
  final DateTime? publishedAt;
  final String? downloadUrl;
  final String htmlUrl;
  final UpdateChannel channel;

  const GitHubRelease({
    required this.version,
    required this.releaseNotes,
    required this.publishedAt,
    required this.downloadUrl,
    required this.htmlUrl,
    required this.channel,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'releaseNotes': releaseNotes,
      'publishedAt': publishedAt?.toIso8601String(),
      'downloadUrl': downloadUrl,
      'htmlUrl': htmlUrl,
      'channel': channel.name,
    };
  }

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      version: json['version'] as String? ?? '0.0.0',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      downloadUrl: json['downloadUrl'] as String?,
      htmlUrl: json['htmlUrl'] as String? ?? '',
      channel: UpdateChannel.values.firstWhere(
        (item) => item.name == json['channel'],
        orElse: () => UpdateChannel.stable,
      ),
    );
  }
}

class GitHubReleaseService {
  final String owner;
  final String repo;
  final http.Client _client;

  GitHubReleaseService({
    String owner = const String.fromEnvironment(
      'BINGIETV_GITHUB_OWNER',
      defaultValue: 'bsogulcan',
    ),
    String repo = const String.fromEnvironment(
      'BINGIETV_GITHUB_REPO',
      defaultValue: 'another-iptv-player',
    ),
    http.Client? client,
  })  : owner = owner.trim(),
        repo = repo.trim(),
        _client = client ?? http.Client();

  Future<GitHubRelease?> fetchLatestRelease(UpdateChannel channel) async {
    final uri = Uri.https('api.github.com', '/repos/$owner/$repo/releases');
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GitHubReleaseException('GitHub HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('GitHub releases response must be a list.');
    }

    final releases = decoded
        .whereType<Map<String, dynamic>>()
        .where((json) => json['draft'] != true)
        .map(_fromGitHubJson)
        .where((release) => release.channel == channel)
        .toList();

    if (releases.isEmpty) return null;
    releases.sort((a, b) {
      final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return releases.first;
  }

  GitHubRelease _fromGitHubJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final name = (json['name'] as String? ?? tag).trim();
    final version = _normalizeVersion(tag.isEmpty ? name : tag);
    final prerelease = json['prerelease'] == true;
    final channel = _detectChannel(tag, name, prerelease);

    return GitHubRelease(
      version: version,
      releaseNotes: json['body'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      downloadUrl: _pickAssetUrl(json['assets']),
      htmlUrl: json['html_url'] as String? ?? '',
      channel: channel,
    );
  }

  UpdateChannel _detectChannel(String tag, String name, bool prerelease) {
    final marker = '$tag $name'.toLowerCase();
    if (marker.contains('dev') ||
        marker.contains('alpha') ||
        marker.contains('nightly')) {
      return UpdateChannel.development;
    }
    if (marker.contains('beta') || marker.contains('rc')) {
      return UpdateChannel.beta;
    }
    return prerelease ? UpdateChannel.beta : UpdateChannel.stable;
  }

  String? _pickAssetUrl(dynamic assets) {
    if (assets is! List) return null;
    final typed = assets.whereType<Map<String, dynamic>>().toList();
    if (typed.isEmpty) return null;
    final preferred = typed.firstWhere(
      (asset) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        return name.endsWith('.apk') || name.endsWith('.exe') || name.endsWith('.msi');
      },
      orElse: () => typed.first,
    );
    return preferred['browser_download_url'] as String?;
  }

  String _normalizeVersion(String value) {
    return value.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
  }
}

class GitHubReleaseException implements Exception {
  final String message;

  const GitHubReleaseException(this.message);

  @override
  String toString() => message;
}
