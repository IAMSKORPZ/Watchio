import 'package:another_iptv_player/repositories/user_preferences.dart';
import 'package:another_iptv_player/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:another_iptv_player/controllers/iptv_controller.dart';
import 'package:another_iptv_player/models/api_configuration_model.dart';
import 'package:another_iptv_player/models/playlist_model.dart';
import 'package:another_iptv_player/models/progress_step.dart';
import 'package:another_iptv_player/repositories/iptv_repository.dart';
import 'package:another_iptv_player/l10n/localization_extension.dart';
import 'package:provider/provider.dart';
import 'xtream_code_home_screen.dart';
import '../playlist_screen.dart';

class XtreamCodeDataLoaderScreen extends StatefulWidget {
  final Playlist playlist;
  final bool refreshAll;

  const XtreamCodeDataLoaderScreen({
    super.key,
    required this.playlist,
    this.refreshAll = false,
  });

  @override
  XtreamCodeDataLoaderScreenState createState() =>
      XtreamCodeDataLoaderScreenState();
}

class XtreamCodeDataLoaderScreenState extends State<XtreamCodeDataLoaderScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late IptvController _controller;

  Map<ProgressStep, String> get stepDisplayNames => {
    ProgressStep.userInfo: 'INITIALISING',
    ProgressStep.categories: 'LOADING CATEGORIES',
    ProgressStep.liveChannels: 'LOADING CHANNELS',
    ProgressStep.movies: 'LOADING MOVIES',
    ProgressStep.series: 'LOADING SERIES',
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    final repository = IptvRepository(
      ApiConfig(
        baseUrl: widget.playlist.url!,
        username: widget.playlist.username!,
        password: widget.playlist.password!,
      ),
      widget.playlist.id,
    );
    _controller = IptvController(repository, widget.refreshAll);

    _startLoading();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startLoading() async {
    final success = await _controller.loadAllData();

    if (success) {
      if (mounted) {
        _animationController.animateTo(1.0);
        await Future.delayed(const Duration(milliseconds: 1000));
        
        AppState.currentPlaylist = widget.playlist;
        await UserPreferences.setLastPlaylist(widget.playlist.id);
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: _controller,
                child: XtreamCodeHomeScreen(playlist: widget.playlist),
              ),
            ),
            (route) => false,
          );
        }
      }
    }
  }

  double _getProgressValue(ProgressStep step) {
    switch (step) {
      case ProgressStep.userInfo: return 0.2;
      case ProgressStep.categories: return 0.4;
      case ProgressStep.liveChannels: return 0.6;
      case ProgressStep.movies: return 0.8;
      case ProgressStep.series: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1423), Color(0xFF050816)],
          ),
        ),
        child: ChangeNotifierProvider.value(
          value: _controller,
          child: Consumer<IptvController>(
            builder: (context, controller, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _animationController.animateTo(_getProgressValue(controller.currentStep));
                }
              });

              return SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      // Logo with Ambient Glow
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC12CFF).withValues(alpha: 0.15),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: const Color(0xFF00B7FF).withValues(alpha: 0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 180,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.play_arrow_rounded, color: Color(0xFF00B7FF), size: 100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'WATCHIO IPTV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Loading your entertainment',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const Spacer(flex: 2),

                      // Modern Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return Column(
                                  children: [
                                    Container(
                                      width: 400,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _progressAnimation.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFC12CFF), Color(0xFF00B7FF)],
                                            ),
                                            borderRadius: BorderRadius.circular(5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00B7FF).withValues(alpha: 0.4),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      stepDisplayNames[controller.currentStep] ?? 'FINALISING',
                                      style: const TextStyle(
                                        color: Color(0xFF00B7FF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    if (controller.importProgress != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '${controller.importProgress!.processedItems} items',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white38,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Error handling
                      if (controller.errorMessage != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  context.loc.error_occurred,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  controller.errorMessage!,
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PlaylistScreen()),
                                      (route) => false,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B7FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(context.loc.close.toUpperCase()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
