import 'package:flutter/material.dart';

Future<String?> showContentSortDialog(
  BuildContext context,
  String currentValue,
  String sectionName,
) {
  var pending = currentValue;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        backgroundColor: const Color(0xFF111525),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.swap_vert_rounded, color: Color(0xFF06B6D4)),
            const SizedBox(width: 10),
            Text(
              'Sort $sectionName',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in const [
              ('server', 'Server Order'),
              ('recent', 'Recently Added'),
              ('az', 'A–Z'),
              ('za', 'Z–A'),
            ])
              ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                minTileHeight: 44,
                leading: Icon(
                  pending == option.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: pending == option.$1
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white54,
                ),
                title: Text(
                  option.$2,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => setDialogState(() => pending = option.$1),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, pending),
            child: const Text('SAVE'),
          ),
        ],
      ),
    ),
  );
}
