import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/api_response.dart';
import '../../../services/app_state.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  ApiResponse? _account;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await AppState.xtreamCodeRepository?.getPlayerInfo();
      if (mounted) setState(() => _account = account);
    } catch (_) {
      // Playlist fallback remains visible when provider account API is offline.
    }
  }

  String _formatExpiration(String? value) {
    if (value == null || value.isEmpty || value == '0') return 'Unlimited';
    final timestamp = int.tryParse(value);
    if (timestamp == null) return value;
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    ).toLocal();
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = _account?.userInfo;
    final serverInfo = _account?.serverInfo;
    final playlist = AppState.currentPlaylist;

    return WatchioSettingsScaffold(
      title: 'ACCOUNT INFORMATION',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AccountDetailRow(
                    label: 'Username',
                    value:
                        userInfo?.username ?? playlist?.username ?? 'Unknown',
                  ),
                  const Divider(color: Colors.white10, height: 28),
                  _AccountDetailRow(
                    label: 'Provider',
                    value: serverInfo?.url ?? playlist?.url ?? 'Unknown',
                  ),
                  const Divider(color: Colors.white10, height: 28),
                  _AccountDetailRow(
                    label: 'Expiration Date',
                    value: _formatExpiration(userInfo?.expDate),
                  ),
                  const Divider(color: Colors.white10, height: 28),
                  _AccountDetailRow(
                    label: 'Connection Status',
                    value: userInfo == null
                        ? 'Loading…'
                        : (userInfo.auth == 1 ? 'Online' : 'Offline'),
                    isStatus: true,
                    statusColor: userInfo?.auth == 1
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                  const Divider(color: Colors.white10, height: 28),
                  _AccountDetailRow(
                    label: 'Active Connections',
                    value:
                        '${userInfo?.activeCons ?? 0} / ${userInfo?.maxConnections ?? "Unlimited"}',
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
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
              Flexible(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
