import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeFooter extends StatelessWidget {
  final String username;
  final String expiryDate;
  final String version;

  const HomeFooter({
    super.key,
    required this.username,
    required this.expiryDate,
    required this.version,
  });

  String _formatExpiry(String date) {
    if (date.isEmpty || date.toLowerCase() == 'n/a') return 'N/A';
    
    final timestamp = int.tryParse(date);
    if (timestamp != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return DateFormat('dd MMM yyyy').format(dt);
    }
    
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final String formattedExpiry = _formatExpiry(expiryDate);
    
    return Row(
      children: [
        // LEFT: Expiration
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_outlined, color: Color(0xFF00B7FF), size: 18),
            const SizedBox(width: 8),
            Text(
              'Expiration: $formattedExpiry',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const Spacer(),
        
        // CENTER: Version
        Text(
          'v$version',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5), // Increased opacity from 0.2 to 0.5
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const Spacer(),
        
        // RIGHT: Profile
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_rounded, color: Color(0xFFC12CFF), size: 18),
            const SizedBox(width: 8),
            Text(
              'Logged In: $username',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
