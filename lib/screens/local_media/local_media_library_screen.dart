import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/config_service.dart';
import '../../models/playlist_content_model.dart';
import '../../models/content_type.dart';
import '../player/unified_player_screen.dart';

class LocalMediaLibraryScreen extends StatefulWidget {
  const LocalMediaLibraryScreen({super.key});

  @override
  State<LocalMediaLibraryScreen> createState() => _LocalMediaLibraryScreenState();
}

class _LocalMediaLibraryScreenState extends State<LocalMediaLibraryScreen> {
  bool _isScanning = false;
  List<File> _recentMedia = [];
  final double _usedStorage = 128.0; // Mocked
  final double _totalStorage = 256.0; // Mocked
  
  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    bool granted = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        granted = statuses.values.every((s) => s.isGranted);
      } else {
        final status = await Permission.storage.request();
        granted = status.isGranted;
      }
    } else {
      granted = true; // For Desktop/Desktop-like
    }

    if (granted) {
      _scanStorage();
    }
  }

  Future<void> _scanStorage() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    try {
      final List<Directory> searchDirs = [];
      
      if (Platform.isAndroid) {
        final List<String> commonPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/DCIM',
        ];
        for (var p in commonPaths) {
          final d = Directory(p);
          if (await d.exists()) searchDirs.add(d);
        }
      } else {
        searchDirs.add(await getApplicationDocumentsDirectory());
        final downloads = await getDownloadsDirectory();
        if (downloads != null) searchDirs.add(downloads);
      }

      List<File> discovered = [];
      for (var dir in searchDirs) {
        try {
          final entities = dir.listSync(recursive: false);
          for (var entity in entities) {
            if (entity is File) {
              final ext = entity.path.split('.').last.toLowerCase();
              if (['mp4', 'mkv', 'mov', 'avi', 'webm', 'mp3', 'flac', 'wav', 'jpg', 'png', 'webp'].contains(ext)) {
                discovered.add(entity);
              }
            }
          }
        } catch (e) {
          debugPrint('Error scanning ${dir.path}: $e');
        }
      }

      // Sort by modified date
      discovered.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      if (mounted) {
        setState(() {
          _recentMedia = discovered.take(10).toList();
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _openFilePicker(FileType type) async {
    final result = await FilePicker.pickFiles(type: type);
    if (result != null && result.files.single.path != null) {
      _playFile(File(result.files.single.path!));
    }
  }

  void _playFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    final String fileName = file.path.split(Platform.pathSeparator).last;
    
    ContentType contentType;
    if (['mp4', 'mkv', 'mov', 'avi', 'webm'].contains(ext)) {
      contentType = ContentType.vod;
    } else if (['mp3', 'flac', 'wav', 'aac', 'ogg'].contains(ext)) {
      contentType = ContentType.vod; 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $fileName')));
      return;
    }

    final contentItem = ContentItem(
      file.path,
      fileName,
      '',
      contentType,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedPlayerScreen(contentItem: contentItem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>().config;
    final loginBg = config.backgrounds.login;

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final bool isMobile = width < 700;
          final bool isTV = width >= 1600;

          double logoWidth = isMobile ? 120 : (isTV ? 210 : 165);

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.97 + (0.03 * value),
                  child: child,
                ),
              );
            },
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: loginBg.isNotEmpty
                      ? NetworkImage(loginBg)
                      : const AssetImage('assets/images/background.png') as ImageProvider,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Fixed Left Panel
                    if (!isMobile)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFC12CFF).withValues(alpha: 0.1),
                                        blurRadius: 35,
                                        spreadRadius: 12,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF00B7FF).withValues(alpha: 0.08),
                                        blurRadius: 30,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: logoWidth,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => 
                                      Icon(Icons.play_arrow_rounded, color: const Color(0xFF00B7FF), size: logoWidth * 0.4),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _SideButton(
                                  icon: Icons.storage_rounded,
                                  label: 'SCAN STORAGE',
                                  height: 60,
                                  onTap: _scanStorage,
                                ),
                                const SizedBox(height: 16),
                                _SideButton(
                                  icon: Icons.refresh_rounded,
                                  label: 'REFRESH LIBRARY',
                                  height: 60,
                                  onTap: _scanStorage,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Scrollable Right Panel
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 24, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row (Fixed at top of right panel)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'LOCAL MEDIA LIBRARY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 22 : 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                _HeaderClock(),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Scrollable content area
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isScanning)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 60),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              const CircularProgressIndicator(color: Color(0xFF00B7FF)),
                                              const SizedBox(height: 24),
                                              const Text(
                                                'SCANNING FOR MEDIA...',
                                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else if (_recentMedia.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 40),
                                        child: _EmptyLibraryPlaceholder(onScan: _scanStorage),
                                      )
                                    else ...[
                                      // Category Cards
                                      SizedBox(
                                        height: isMobile ? 110 : 170,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _CategoryCard(
                                                title: 'VIDEOS',
                                                subtitle: 'Movies, TV Shows, Home Videos',
                                                icon: Icons.video_library_rounded,
                                                gradient: const [Color(0xFF00B7FF), Color(0xFF0066FF)],
                                                onTap: () => _openFilePicker(FileType.video),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _CategoryCard(
                                                title: 'MUSIC',
                                                subtitle: 'Albums, Artists, Playlists',
                                                icon: Icons.music_note_rounded,
                                                gradient: const [Color(0xFFC12CFF), Color(0xFF8A00FF)],
                                                onTap: () => _openFilePicker(FileType.audio),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _CategoryCard(
                                                title: 'PHOTOS',
                                                subtitle: 'Pictures, Screenshots, Camera',
                                                icon: Icons.image_rounded,
                                                gradient: const [Color(0xFFFF2D55), Color(0xFFFF3B30)],
                                                onTap: () => _openFilePicker(FileType.image),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _CategoryCard(
                                                title: 'FOLDERS',
                                                subtitle: 'Browse Device Storage',
                                                icon: Icons.folder_rounded,
                                                gradient: const [Color(0xFF4CD964), Color(0xFF28CD41)],
                                                onTap: () => _openFilePicker(FileType.any),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      const Text(
                                        'RECENTLY ADDED',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 210,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _recentMedia.length,
                                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                                          itemBuilder: (context, index) {
                                            final file = _recentMedia[index];
                                            return _RecentMediaCard(
                                              file: file,
                                              onTap: () => _playFile(file),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                    ],
                                    
                                    // Storage Panel (Stays at bottom of scroll content)
                                    _StoragePanel(used: _usedStorage, total: _totalStorage),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyLibraryPlaceholder extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyLibraryPlaceholder({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1423).withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00B7FF).withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.auto_awesome_motion_rounded, size: 64, color: const Color(0xFF00B7FF).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Media Found',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan your device storage to build your media library.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 220,
            child: _SideButton(
              icon: Icons.search_rounded,
              label: 'SCAN STORAGE',
              height: 54,
              onTap: onScan,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderClock extends StatefulWidget {
  @override
  State<_HeaderClock> createState() => _HeaderClockState();
}

class _HeaderClockState extends State<_HeaderClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
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
      children: [
        Text(
          DateFormat('hh:mm a').format(_now),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(
          DateFormat('MMM d, yyyy').format(_now),
          style: const TextStyle(color: Color(0xFFC12CFF), fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1423).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isFocused ? const Color(0xFF00B7FF) : Colors.white10,
                width: _isFocused ? 2.5 : 1,
              ),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: const Color(0xFF00B7FF).withValues(alpha: 0.3),
                  blurRadius: 20,
                )
              ] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Icon(widget.icon, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentMediaCard extends StatefulWidget {
  final File file;
  final VoidCallback onTap;
  const _RecentMediaCard({required this.file, required this.onTap});

  @override
  State<_RecentMediaCard> createState() => _RecentMediaCardState();
}

class _RecentMediaCardState extends State<_RecentMediaCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final String fileName = widget.file.path.split(Platform.pathSeparator).last;
    final String extension = fileName.split('.').last.toUpperCase();
    final int sizeBytes = widget.file.lengthSync();
    final String sizeStr = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    IconData typeIcon = Icons.insert_drive_file_rounded;
    bool isImage = false;
    if (['MP4', 'MKV', 'MOV', 'AVI', 'WEBM'].contains(extension)) typeIcon = Icons.play_circle_fill_rounded;
    if (['MP3', 'FLAC', 'WAV'].contains(extension)) typeIcon = Icons.music_note_rounded;
    if (['JPG', 'PNG', 'WEBP'].contains(extension)) {
      typeIcon = Icons.image_rounded;
      isImage = true;
    }

    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1423).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFocused ? const Color(0xFFC12CFF) : Colors.white10,
                width: _isFocused ? 2.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(color: Colors.black26),
                          child: isImage 
                            ? Image.file(widget.file, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(typeIcon, size: 48, color: Colors.white10))
                            : Center(
                                child: Icon(typeIcon, size: 48, color: const Color(0xFFC12CFF).withValues(alpha: 0.5)),
                              ),
                        ),
                      ),
                      if (!isImage)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            sizeStr,
                            style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: Colors.white10, fontSize: 11)),
                          const SizedBox(width: 6),
                          Text(
                            extension,
                            style: const TextStyle(color: Color(0xFF00B7FF), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoragePanel extends StatelessWidget {
  final double used;
  final double total;

  const _StoragePanel({required this.used, required this.total});

  @override
  Widget build(BuildContext context) {
    final double percent = used / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1423).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open_rounded, color: Color(0xFFC12CFF), size: 24),
          const SizedBox(width: 16),
          const Text(
            'INTERNAL STORAGE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFC12CFF), Color(0xFF00B7FF)]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            '${used.toInt()} GB / ${total.toInt()} GB',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}

class _SideButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double height;

  const _SideButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.height,
  });

  @override
  State<_SideButton> createState() => _SideButtonState();
}

class _SideButtonState extends State<_SideButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  bool get _isActive => _isFocused || _isHovered;

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isActive ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: _isActive ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isActive ? const Color(0xFF00B7FF) : Colors.white10,
                width: _isActive ? 3.0 : 1,
              ),
              boxShadow: _isActive ? [
                BoxShadow(
                  color: const Color(0xFFC12CFF).withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF00B7FF).withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 1,
                )
              ] : [],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(widget.icon, color: _isActive ? const Color(0xFF00B7FF) : Colors.white70, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: _isActive ? Colors.white : Colors.white70,
                        fontSize: 14,
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
    );
  }
}
