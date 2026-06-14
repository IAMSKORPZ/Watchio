import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../core/theme/theme_extensions.dart';
import 'm3u/new_m3u_playlist_screen.dart';
import 'xtream-codes/new_xtream_code_playlist_screen.dart';
import 'local_media/local_media_library_screen.dart';

class PlaylistTypeScreen extends StatefulWidget {
  const PlaylistTypeScreen({super.key});

  @override
  State<PlaylistTypeScreen> createState() => _PlaylistTypeScreenState();
}

class _PlaylistTypeScreenState extends State<PlaylistTypeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>().config;
    
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Responsive Breakpoints
          final bool isMobile = width < 700;
          final bool isTV = width >= 1600;

          // Logo Scaling - Refined size increase
          double logoHeight;
          if (isMobile) {
            logoHeight = 95; // Increased by ~18%
          } else if (isTV) {
            logoHeight = 190; // Increased by ~18%
          } else {
            logoHeight = 140; // Increased by ~16%
          }

          // Title sizing and gaps
          double titleFontSize = isMobile ? 22 : (isTV ? 36 : 30);
          double titleGap = isMobile ? 15 : (isTV ? 25 : 20);

          // Tile Sizing (Fixed per breakpoint)
          double cardWidth;
          double cardHeight;
          if (isMobile) {
            cardWidth = width * 0.23; // Reduced from 0.28 (~18% reduction)
            cardHeight = 110;
          } else if (isTV) {
            cardWidth = 270; // Reduced from 320 (~15% reduction)
            cardHeight = 210;
          } else {
            cardWidth = 220; // Reduced from 260 (~15% reduction)
            cardHeight = 170;
          }

          // Emergency scaling if height is critically low
          // (e.g. mobile landscape)
          if (height < 450) {
            cardHeight *= 0.7;
            logoHeight *= 0.7;
            titleGap *= 0.5;
          }

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: config.backgrounds.home.isNotEmpty
                    ? NetworkImage(config.backgrounds.home)
                    : const AssetImage('assets/images/background.png') as ImageProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.4),
                  BlendMode.darken,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/App_Logo.png',
                          height: logoHeight,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.play_arrow_rounded, color: const Color(0xFF00B7FF), size: logoHeight * 0.7),
                        ),
                        const Spacer(),
                        const _LiveClock(),
                      ],
                    ),
                  ),
                  
                  const Spacer(flex: 1), // Top breathing room
                  
                  // 2. Title - Moved upward for better balance
                  Transform.translate(
                    offset: const Offset(0, -25),
                    child: Text(
                      'CHOOSE PLAYLIST TYPE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: titleGap), // Use the titleGap variable
                  
                  // 3. Main Dashboard (Expanded & Centered)
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _TypeCard(
                              title: 'M3U PLAYLIST',
                              icon: Icons.playlist_play_rounded,
                              width: cardWidth,
                              height: cardHeight,
                              onTap: () => _navToM3u(context),
                            ),
                            const SizedBox(width: 20),
                            _TypeCard(
                              title: 'XTREAM CODE',
                              icon: Icons.stream_rounded,
                              width: cardWidth,
                              height: cardHeight,
                              onTap: () => _navToXtream(context),
                            ),
                            const SizedBox(width: 20),
                            _TypeCard(
                              title: 'LOCAL DATA',
                              icon: Icons.folder_open_rounded,
                              width: cardWidth,
                              height: cardHeight,
                              onTap: () => _showLocalDataMsg(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 3), // Bottom Spacer - larger flex to push everything UP
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navToM3u(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NewM3uPlaylistScreen()));
  }

  void _navToXtream(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NewXtreamCodePlaylistScreen()));
  }

  void _showLocalDataMsg(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocalMediaLibraryScreen()),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('hh:mm a').format(_now),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(
          DateFormat('MMM d, yyyy').format(_now),
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _TypeCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _TypeCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  bool get active => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
      onShowHoverHighlight: (val) => setState(() => _isHovered = val),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active 
                      ? const Color(0xFF00B7FF)
                      : Colors.white.withValues(alpha: 0.15),
                  width: active ? 3 : 1.5,
                ),
                boxShadow: active ? [
                  BoxShadow(
                    color: const Color(0xFFC12CFF).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ] : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: BingieThemeExtension.of(context).glassGradient,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: active ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFC12CFF), Color(0xFF00B7FF)],
                            ).createShader(bounds),
                            child: Icon(widget.icon, size: 48, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16), 
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
