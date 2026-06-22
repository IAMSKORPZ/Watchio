import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../settings/widgets/watchio_settings_scaffold.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  static final _endpoint = Uri.parse(
    'https://watchio-bug-reporter.iamskorpz26.workers.dev',
  );

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _steps = TextEditingController();
  final _expected = TextEditingController();
  final _contact = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _steps.dispose();
    _expected.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _sending) return;
    setState(() => _sending = true);
    try {
      final package = await PackageInfo.fromPlatform();
      final response = await http
          .post(
            _endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': _title.text,
              'description': _description.text,
              'steps': _steps.text,
              'expected': _expected.text,
              'contact': _contact.text,
              'appVersion': '${package.version}+${package.buildNumber}',
              'platform':
                  '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
              'website': '',
            }),
          )
          .timeout(const Duration(seconds: 20));
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(result['error'] ?? 'Report could not be sent.');
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Bug Report Sent'),
          content: Text(
            'Thank you. GitHub issue #${result['issue'] ?? ''} was created.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('DONE'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bug report failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'REPORT A BUG',
      onBack: () => Navigator.pop(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              children: [
                _field(
                  controller: _title,
                  label: 'Short title',
                  validator: (value) => (value?.trim().length ?? 0) < 5
                      ? 'Enter at least 5 characters.'
                      : null,
                ),
                _field(
                  controller: _description,
                  label: 'What went wrong?',
                  lines: 3,
                  validator: (value) => (value?.trim().length ?? 0) < 10
                      ? 'Enter at least 10 characters.'
                      : null,
                ),
                _field(
                  controller: _steps,
                  label: 'Steps to reproduce',
                  lines: 3,
                ),
                _field(
                  controller: _expected,
                  label: 'What should have happened?',
                  lines: 2,
                ),
                _field(controller: _contact, label: 'Contact email (optional)'),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bug_report_rounded),
                  label: Text(_sending ? 'SENDING...' : 'SEND BUG REPORT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    int lines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
