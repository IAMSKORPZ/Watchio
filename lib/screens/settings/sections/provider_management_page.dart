import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers/provider_controller.dart';
import '../../../models/provider_model.dart';
import '../provider_form_screen.dart';
import '../widgets/watchio_settings_scaffold.dart';

class ProviderManagementPage extends StatelessWidget {
  const ProviderManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProviderController()..loadProviders(),
      child: const _ProviderManagementView(),
    );
  }
}

class _ProviderManagementView extends StatelessWidget {
  const _ProviderManagementView();

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'PROVIDER MANAGEMENT',
      onBack: () => Navigator.pop(context),
      child: Consumer<ProviderController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                  child: Text(
                    controller.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              Expanded(
                child: controller.isLoading && controller.providers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.providers.isEmpty
                    ? const Center(
                        child: Text(
                          'No providers added yet',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(40, 4, 40, 8),
                        itemCount: controller.providers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _ProviderTile(
                          provider: controller.providers[index],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 4, 40, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoading
                        ? null
                        : () => _openForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ADD NEW PROVIDER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC12CFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, [IptvProvider? provider]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProviderFormScreen(provider: provider)),
    );
    if (changed == true && context.mounted) {
      await context.read<ProviderController>().loadProviders();
    }
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider});

  final IptvProvider provider;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ProviderController>();
    final statusColor = switch (provider.status) {
      ProviderStatus.online => Colors.greenAccent,
      ProviderStatus.offline => Colors.redAccent,
      ProviderStatus.authFailed => Colors.orangeAccent,
      ProviderStatus.unknown => Colors.white38,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF292342).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: provider.isDefault ? const Color(0xFFC12CFF) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.dns_rounded, color: statusColor, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${provider.type.label}  •  ${provider.status.label}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          if (provider.isDefault)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('DEFAULT')),
            ),
          Switch(
            value: provider.enabled,
            onChanged: (value) => controller.setEnabled(provider.id, value),
          ),
          IconButton(
            tooltip: 'Check status',
            onPressed: () => controller.checkStatus(provider.id),
            icon: const Icon(Icons.wifi_tethering_rounded),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () =>
                _ProviderManagementView()._openForm(context, provider),
            icon: const Icon(Icons.edit_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'default') {
                await controller.setDefaultProvider(provider.id);
              } else if (action == 'delete' && context.mounted) {
                await _delete(context, controller);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'default', child: Text('Set as default')),
              PopupMenuItem(value: 'delete', child: Text('Delete provider')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    ProviderController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Delete ${provider.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteProvider(provider.id);
  }
}
