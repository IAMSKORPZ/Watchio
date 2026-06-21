import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/trakt_service.dart';
import '../settings/widgets/watchio_settings_scaffold.dart';

class TraktScreen extends StatefulWidget {
  const TraktScreen({super.key});

  @override
  State<TraktScreen> createState() => _TraktScreenState();
}

class _TraktScreenState extends State<TraktScreen> {
  final _service = TraktService();
  bool _loading = true;
  bool _loggedIn = false;
  String? _error;
  Map<String, dynamic>? _settings;
  List<Map<String, dynamic>> _watchlist = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loggedIn = await _service.isLoggedIn;
      if (!loggedIn) {
        if (mounted) setState(() => _loggedIn = false);
        return;
      }
      final data = await Future.wait([
        _service.getSettings(),
        _service.getWatchlist(),
        _service.getHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _settings = data[0] as Map<String, dynamic>;
        _watchlist = data[1] as List<Map<String, dynamic>>;
        _history = data[2] as List<Map<String, dynamic>>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    try {
      final code = await _service.requestDeviceCode();
      if (!mounted) return;
      unawaited(launchUrl(Uri.parse(code.verificationUrl)));
      var dialogActive = true;
      var authorized = false;
      unawaited(() async {
        authorized = await _service.waitForAuthorization(code);
        if (authorized && mounted && dialogActive) {
          Navigator.of(context, rootNavigator: true).pop(false);
        }
      }());
      final cancelled = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF121629),
          title: const Text('Connect Trakt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter this code on the Trakt activation page:'),
                const SizedBox(height: 18),
                SelectableText(
                  code.userCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC12CFF),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(code.verificationUrl),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      );
      dialogActive = false;
      if (cancelled == true) return;
      if (authorized && mounted) await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'MY TRAKT',
      onBack: () => Navigator.pop(context),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _Message(message: _error!, action: _load, actionLabel: 'RETRY')
          : !_loggedIn
          ? _Message(
              message:
                  'Connect your Trakt account to see your watchlist and history.',
              action: _login,
              actionLabel: 'CONNECT TRAKT',
            )
          : _library(),
    );
  }

  Widget _library() {
    final user = _settings?['user'] as Map<String, dynamic>?;
    final name = user?['name'] ?? user?['username'] ?? 'Trakt User';
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                const Icon(Icons.account_circle, size: 36),
                const SizedBox(width: 12),
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await _service.logout();
                    await _load();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('LOG OUT'),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'WATCHLIST'),
              Tab(text: 'HISTORY'),
            ],
          ),
          Expanded(
            child: TabBarView(children: [_items(_watchlist), _items(_history)]),
          ),
        ],
      ),
    );
  }

  Widget _items(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const Center(child: Text('Nothing here yet.'));
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 2.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        final media =
            (item['movie'] ?? item['show']) as Map<String, dynamic>? ??
            const {};
        return Card(
          child: ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(media['title']?.toString() ?? 'Unknown', maxLines: 2),
            subtitle: Text(media['year']?.toString() ?? ''),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.message,
    required this.action,
    required this.actionLabel,
  });
  final String message;
  final VoidCallback action;
  final String actionLabel;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.playlist_add_check_rounded,
          size: 72,
          color: Color(0xFFC12CFF),
        ),
        const SizedBox(height: 18),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(onPressed: action, child: Text(actionLabel)),
      ],
    ),
  );
}
