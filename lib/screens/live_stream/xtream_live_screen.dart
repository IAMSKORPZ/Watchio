import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/xtream_code_home_controller.dart';
import '../../models/category_type.dart';
import '../../models/category_view_model.dart';
import '../../models/content_type.dart';
import '../../models/playback_item.dart';
import '../../models/player_engine.dart';
import '../../models/playlist_content_model.dart';
import '../../repositories/iptv_repository.dart';
import '../../repositories/user_preferences.dart';
import '../../services/config_service.dart';
import '../../services/epg_storage_service.dart';
import '../../services/player/app_player_controller.dart';
import '../../services/player/player_factory.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../shared/widgets/watchio_header.dart';
import '../../utils/navigate_by_content_type.dart';
import '../player/unified_player_screen.dart';
import '../search_screen.dart';

class XtreamLiveScreen extends StatefulWidget {
  const XtreamLiveScreen({super.key});

  @override
  State<XtreamLiveScreen> createState() => _XtreamLiveScreenState();
}

class _XtreamLiveScreenState extends State<XtreamLiveScreen> {
  CategoryViewModel? _selectedCategory;
  ContentItem? _focusedChannel;
  final List<ContentItem> _currentItems = [];
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 60;
  final Map<String, int> _categoryCounts = {};

  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _channelScrollController = ScrollController();
  
  List<EpgProgramWindow> _epgPrograms = [];
  final _epgService = EpgStorageService();

  AppPlayerController? _previewController;
  Timer? _previewDebounce;
  bool _previewFocused = false;

  @override
  void initState() {
    super.initState();
    _initPreviewController();
    _channelScrollController.addListener(_scrollListener);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<XtreamCodeHomeController>(context, listen: false);
      if (controller.liveCategories != null && controller.liveCategories!.isNotEmpty) {
        // Load all category counts in bulk
        final counts = await controller.getAllCategoryCounts(CategoryType.live);
        if (mounted) {
          setState(() {
            _categoryCounts.addAll(counts);
            _onCategorySelected(controller.liveCategories!.first);
          });
        }
      }
    });
  }

  Future<void> _initPreviewController() async {
    final engineStr = await UserPreferences.getPlayerEngine();
    final engine = PlayerEngine.values.firstWhere(
      (e) => e.name == engineStr, 
      orElse: () => PlayerEngine.auto
    );
    _previewController = PlayerFactory.create(engine);
    await _previewController!.initialize();
    _previewController!.addListener(_onPreviewStateChanged);
  }

  void _onPreviewStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _previewController?.removeListener(_onPreviewStateChanged);
    _previewController?.dispose();
    _channelScrollController.removeListener(_scrollListener);
    _categoryScrollController.dispose();
    _channelScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_channelScrollController.position.pixels >= _channelScrollController.position.maxScrollExtent - 400) {
      if (!_isMoreLoading && _hasMore) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _onCategorySelected(CategoryViewModel category) async {
    setState(() {
      _selectedCategory = category;
      _currentItems.clear();
      _currentOffset = 0;
      _hasMore = true;
      _isMoreLoading = true;
      _focusedChannel = null;
      _epgPrograms = [];
    });

    await _loadMoreItems();

    if (_currentItems.isNotEmpty && mounted) {
      setState(() {
        _focusedChannel = _currentItems.first;
      });
      _fetchEpg(_focusedChannel!);
    }
  }

  Future<void> _loadMoreItems() async {
    if (_selectedCategory == null) return;
    
    setState(() => _isMoreLoading = true);
    
    try {
      final controller = Provider.of<XtreamCodeHomeController>(context, listen: false);
      final newItems = await controller.getCategoryItems(
        _selectedCategory!.category,
        top: _pageSize,
        offset: _currentOffset,
      );

      if (mounted) {
        setState(() {
          _currentItems.addAll(newItems);
          _currentOffset += newItems.length;
          _isMoreLoading = false;
          if (newItems.length < _pageSize) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isMoreLoading = false);
    }
  }

  Future<void> _fetchEpg(ContentItem channel) async {
    if (channel.liveStream == null) return;
    
    final playlistId = channel.liveStream!.playlistId;
    final epgId = channel.liveStream!.epgChannelId;
    
    if (playlistId == null || epgId.isEmpty) {
      setState(() => _epgPrograms = []);
      return;
    }

    try {
      final programs = await _epgService.getProgramsForWindow(
        playlistId: playlistId,
        epgChannelId: epgId,
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 12)),
        limit: 3,
      );
      if (mounted) setState(() => _epgPrograms = programs);
    } catch (e) {
      if (mounted) setState(() => _epgPrograms = []);
    }
  }

  void _onChannelFocused(ContentItem channel) {
    if (_focusedChannel?.id == channel.id) return;
    setState(() {
      _focusedChannel = channel;
    });
    _fetchEpg(channel);

    // Debounce preview playback to prevent rapid stream switching while scrolling
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _previewController != null) {
        _previewController!.setDataSource(PlaybackItem.fromContentItem(channel));
      }
    });
  }

  void _enterFullscreen() {
    if (_focusedChannel == null || _previewController == null) return;
    
    // Remove listener before passing to fullscreen to avoid double state updates
    _previewController!.removeListener(_onPreviewStateChanged);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedPlayerScreen(
          contentItem: _focusedChannel!,
          queue: _currentItems,
          externalController: _previewController,
        ),
      ),
    ).then((_) {
      // Re-attach listener when returning from fullscreen
      if (mounted) {
        _previewController!.addListener(_onPreviewStateChanged);
        
        // Sync focused channel if it changed in fullscreen
        final currentPlayItem = _previewController!.currentItem;
        if (currentPlayItem != null && currentPlayItem.originalItem != null) {
          setState(() {
            _focusedChannel = currentPlayItem.originalItem;
          });
          _fetchEpg(_focusedChannel!);
        }

        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>().config;
    final homeBg = config.backgrounds.home;

    return Consumer<XtreamCodeHomeController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF050812),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF050812),
              image: DecorationImage(
                image: (homeBg.isNotEmpty)
                    ? NetworkImage(homeBg)
                    : const AssetImage('assets/images/background.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF050812).withValues(alpha: 0.2),
                    const Color(0xFF050812).withValues(alpha: 0.6),
                    const Color(0xFF050812).withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // HEADER
                  WatchioHeader(
                    onBack: () => controller.onNavigationTap(0),
                    onSearch: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen(contentType: ContentType.liveStream))),
                    onSettings: () => controller.onNavigationTap(5),
                    onRefresh: () => controller.refreshAllData(context),
                  ),
                  
                  // MAIN CONTENT (3 Columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          // LEFT PANEL (22%) - Categories
                          Expanded(
                            flex: 22,
                            child: _buildCategoryPanel(controller),
                          ),
                          const SizedBox(width: 16),
                          
                          // CENTER PANEL (28%) - Channels
                          Expanded(
                            flex: 28,
                            child: _buildChannelPanel(),
                          ),
                          const SizedBox(width: 16),
                          
                          // RIGHT PANEL (50%) - Preview & EPG
                          Expanded(
                            flex: 50,
                            child: _buildPreviewPanel(),
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
    );
  }

  Widget _buildCategoryPanel(XtreamCodeHomeController controller) {
    final categories = controller.liveCategories ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.separated(
            controller: _categoryScrollController,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory?.category.categoryId == cat.category.categoryId;
              
              return _CategoryItem(
                icon: _getCategoryIcon(cat.category.categoryId),
                label: cat.category.categoryName.toUpperCase(),
                count: _categoryCounts[cat.category.categoryId] ?? 0,
                isSelected: isSelected,
                onTap: () {
                  if (!isSelected) {
                    _onCategorySelected(cat);
                    _channelScrollController.jumpTo(0);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChannelPanel() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _channelScrollController,
            itemCount: _currentItems.length + (_isMoreLoading ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index < _currentItems.length) {
                final channel = _currentItems[index];
                final isFocused = _focusedChannel?.id == channel.id;
                
                return _ChannelItem(
                  channel: channel,
                  index: index + 1,
                  isFocused: isFocused,
                  onFocus: () => _onChannelFocused(channel),
                  onTap: () {
                    if (isFocused) {
                      _enterFullscreen();
                    } else {
                      _onChannelFocused(channel);
                    }
                  },
                );
              } else {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    if (_focusedChannel == null) return const SizedBox.shrink();

    return Column(
      children: [
        // PREVIEW AREA
        Expanded(
          flex: 6,
          child: Focus(
            onFocusChange: (v) => setState(() => _previewFocused = v),
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                _enterFullscreen();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: _enterFullscreen,
              onDoubleTap: _enterFullscreen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _previewFocused ? const Color(0xFFC12CFF) : const Color(0xFFC12CFF).withValues(alpha: 0.3), 
                    width: _previewFocused ? 4 : 2
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC12CFF).withValues(alpha: _previewFocused ? 0.3 : 0.1), 
                      blurRadius: _previewFocused ? 30 : 20, 
                      spreadRadius: 5
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video Preview
                      if (_previewController != null)
                        _previewController!.buildPlayerView(context)
                      else if (_focusedChannel!.imagePath.isNotEmpty)
                        Image.network(
                          _focusedChannel!.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.live_tv, size: 80, color: Colors.white10)),
                        ),
                      
                      // Loading indicator for preview
                      if (_previewController?.isBuffering ?? false)
                         const Center(child: CircularProgressIndicator(color: Color(0xFFC12CFF))),

                      // Glass Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                            ),
                          ),
                        ),
                      ),
                      
                      // Fullscreen Icon Hint
                      Positioned(
                        top: 16, right: 16,
                        child: Icon(Icons.fullscreen_rounded, color: Colors.white.withValues(alpha: 0.5), size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // EPG TIMELINE SECTION
        Expanded(
          flex: 4,
          child: GlassPanel(
            padding: const EdgeInsets.all(20),
            child: _epgPrograms.isEmpty
                ? const Center(
                    child: Text(
                      'No EPG Information Available',
                      style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEpgItem('NOW PLAYING', _epgPrograms[0], isNow: true),
                        const Divider(color: Colors.white10, height: 24),
                        _buildEpgItem('UP NEXT', _epgPrograms.length > 1 ? _epgPrograms[1] : null),
                        const Divider(color: Colors.white10, height: 24),
                        _buildEpgItem('LATER', _epgPrograms.length > 2 ? _epgPrograms[2] : null),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpgItem(String header, EpgProgramWindow? program, {bool isNow = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: const TextStyle(color: Color(0xFF00B7FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          program?.title ?? 'No EPG Information Available',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (program != null) ...[
          const SizedBox(height: 2),
          Text(
            '${DateFormat('HH:mm').format(program.start)} - ${DateFormat('HH:mm').format(program.end)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (isNow) ...[
            const SizedBox(height: 8),
            _buildEpgProgressBar(program),
          ],
        ],
      ],
    );
  }

  Widget _buildEpgProgressBar(EpgProgramWindow program) {
    final now = DateTime.now();
    final total = program.end.difference(program.start).inSeconds;
    final elapsed = now.difference(program.start).inSeconds;
    final progress = (elapsed / total).clamp(0.0, 1.0);

    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFC12CFF), Color(0xFF00B7FF)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    if (categoryId == IptvRepository.virtualAll) return Icons.list_rounded;
    if (categoryId == IptvRepository.virtualFavorites) return Icons.favorite_rounded;
    if (categoryId == IptvRepository.virtualHistory) return Icons.history_rounded;
    return Icons.live_tv_rounded;
  }
}

class _CategoryItem extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _CategoryItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || widget.isSelected;
    
    return FocusableActionDetector(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFC12CFF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? const Color(0xFFC12CFF) : Colors.white10,
                width: active ? 2 : 1,
              ),
              boxShadow: _isFocused ? [
                BoxShadow(color: const Color(0xFFC12CFF).withValues(alpha: 0.3), blurRadius: 10)
              ] : [],
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon, 
                  color: active ? Colors.white : Colors.white70, 
                  size: 20
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    color: active ? Colors.white.withValues(alpha: 0.5) : Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

class _ChannelItem extends StatefulWidget {
  final ContentItem channel;
  final int index;
  final bool isFocused;
  final VoidCallback onFocus;
  final VoidCallback onTap;

  const _ChannelItem({
    required this.channel,
    required this.index,
    required this.isFocused,
    required this.onFocus,
    required this.onTap,
  });

  @override
  State<_ChannelItem> createState() => _ChannelItemState();
}

class _ChannelItemState extends State<_ChannelItem> {
  bool _uiFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = _uiFocused || widget.isFocused;
    
    return FocusableActionDetector(
      onFocusChange: (v) {
        setState(() => _uiFocused = v);
        if (v) widget.onFocus();
      },
      child: AnimatedScale(
        scale: _uiFocused ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced vertical padding
            decoration: BoxDecoration(
              color: active ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? const Color(0xFFC12CFF) : Colors.white10,
                width: active ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${widget.index}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34, // Reduced from 40
                  height: 34, // Reduced from 40
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: widget.channel.imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.channel.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.live_tv, size: 18, color: Colors.white24),
                          ),
                        )
                      : const Icon(Icons.live_tv, size: 18, color: Colors.white24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.channel.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1), // Reduced from 2
                      const Text(
                        'No EPG info',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
