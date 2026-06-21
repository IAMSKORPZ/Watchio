import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../controllers/xtream_code_home_controller.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class AccountInfoPage extends StatelessWidget {
  const AccountInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<XtreamCodeHomeController>(context, listen: false);
    final userInfo = homeController.userInfo?.userInfo;
    final serverInfo = homeController.userInfo?.serverInfo;

    return WatchioSettingsScaffold(
      title: 'ACCOUNT INFORMATION',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GlassPanel(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  _AccountDetailRow(label: 'Username', value: userInfo?.username ?? 'Guest'),
                  const Divider(color: Colors.white10, height: 48),
                  _AccountDetailRow(label: 'Provider', value: serverInfo?.url ?? 'Watchio Premium'),
                  const Divider(color: Colors.white10, height: 48),
                  _AccountDetailRow(label: 'Expiration Date', value: userInfo?.expDate ?? 'Unlimited'),
                  const Divider(color: Colors.white10, height: 48),
                  _AccountDetailRow(
                    label: 'Connection Status',
                    value: userInfo?.auth == 1 ? 'Online' : 'Offline',
                    isStatus: true,
                    statusColor: userInfo?.auth == 1 ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const Divider(color: Colors.white10, height: 48),
                  _AccountDetailRow(
                    label: 'Active Connections',
                    value: '${userInfo?.activeCons ?? 0} / ${userInfo?.maxConnections ?? "Unlimited"}',
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

class _AccountDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;
  final Color statusColor;

  const _AccountDetailRow({
    required this.label,
    required this.value,
    this.isStatus = false,
    this.statusColor = Colors.greenAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        Row(
          children: [
            if (isStatus)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
