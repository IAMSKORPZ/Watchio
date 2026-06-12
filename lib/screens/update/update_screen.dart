import 'package:another_iptv_player/controllers/branding_controller.dart';
import 'package:another_iptv_player/controllers/update_controller.dart';
import 'package:another_iptv_player/services/github_release_service.dart';
import 'package:another_iptv_player/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UpdateController>();
    final branding = context.watch<BrandingController>();
    final result = controller.result;

    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                _row(
                  'Current Version',
                  result?.currentVersion ?? controller.currentVersion ?? 'Unknown',
                ),
                const Divider(height: 1),
                _row(
                  'Latest Version',
                  result?.updateInfo.latestVersion ??
                      controller.lastKnownVersion ??
                      'Unknown',
                ),
                const Divider(height: 1),
                _row('Last Check', _format(controller.lastCheckTime)),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Update Channel'),
                  subtitle: Text(controller.channel.name),
                  trailing: DropdownButton<UpdateChannel>(
                    value: controller.channel,
                    items: UpdateChannel.values
                        .map(
                          (channel) => DropdownMenuItem(
                            value: channel,
                            child: Text(channel.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.setChannel(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (result != null) _releaseCard(context, controller, result),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: controller.isChecking
                ? null
                : () => controller.checkForUpdates(
                      remoteUpdateInfo: branding.updateInfo,
                    ),
            icon: const Icon(Icons.system_update_alt),
            label: Text(
              controller.isChecking ? 'Checking...' : 'Check For Updates',
            ),
          ),
          if (controller.error != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(controller.error!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _releaseCard(
    BuildContext context,
    UpdateController controller,
    UpdateCheckResult result,
  ) {
    final release = result.release;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.forceRequired
                  ? 'Update Required'
                  : (result.updateAvailable ? 'Update Available' : 'Up to date'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Version: ${result.updateInfo.latestVersion}'),
            if (release?.publishedAt != null)
              Text('Published: ${_format(release!.publishedAt)}'),
            if (result.forceRequired)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Required update before continuing.'),
              ),
            if ((result.updateInfo.releaseNotes ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(result.updateInfo.releaseNotes!),
            ],
            if (result.updateAvailable || result.forceRequired) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: controller.isDownloading
                          ? null
                          : controller.downloadUpdate,
                      child: Text(
                        controller.isDownloading ? 'Downloading...' : 'Download',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openRelease(release?.htmlUrl),
                      child: const Text('Open Release'),
                    ),
                  ),
                ],
              ),
              if (controller.downloadedInstallerPath != null) ...[
                const SizedBox(height: 8),
                Text('Downloaded: ${controller.downloadedInstallerPath}'),
                const Text(
                  'Open the file to install. Unknown sources may be required on Android/Firestick.',
                ),
                const Text('Windows users should restart BingieTV after the installer completes.'),
                OutlinedButton.icon(
                  onPressed: () =>
                      _openInstaller(controller.downloadedInstallerPath),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Installer'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return ListTile(title: Text(label), subtitle: Text(value), dense: true);
  }

  Future<void> _openRelease(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInstaller(String? path) async {
    if (path == null || path.isEmpty) return;
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _format(DateTime? value) {
    if (value == null) return 'Never';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
