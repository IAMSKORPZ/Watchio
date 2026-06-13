import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/xtream_code_home_controller.dart';
import '../../models/category_view_model.dart';
import '../../models/playlist_content_model.dart';
import '../../services/config_service.dart';
import '../../services/epg_storage_service.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../utils/navigate_by_content_type.dart';

class XtreamLiveScreen extends StatefulWidget {
  const XtreamLiveScreen({super.key});

  @override
  State<XtreamLiveScreen> createState() => _XtreamLiveScreenState();
}

class _XtreamLiveScreenState extends State<XtreamLiveScreen> {
  CategoryViewModel? _selectedCategory;
  ContentItem? _focusedChannel;
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _channelScrollController = ScrollController();
  
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  
  List<EpgProgramWindow> _epgPrograms = [];
  final _epgService = EpgStorageService();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<XtreamCodeHomeController>(context, listen: false);
      if (controller.liveCategories != null && controller.liveCategories!.isNotEmpty) {
        setState(() {
          _selectedCategory = controller.liveCategories!.first;
          if (_selectedCategory!.contentItems.isNotEmpty) {
            _focusedChannel = _selectedCategory!.contentItems.first;
            _fetchEpg(_focusedChannel!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _categoryScrollController.dispose();
    _channelScrollController.dispose();
    super.dispose();
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
                  _buildHeader(context, controller),
                  
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

  Widget _buildHeader(BuildContext context, XtreamCodeHomeController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // LEFT: Back + Logo
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => controller.onNavigationTap(0), // Go back to Home tab
              ),
              const SizedBox(width: 16),
              Image.asset(
                'assets/images/App_Logo.png',
                height: 68, // Increased from 50 (approx +35%)
                fit: BoxFit.contain,
              ),
            ],
          ),
          
          const Spacer(),
          
          // CENTER: Time & Date
          Column(
            children: [
              Text(
                DateFormat('hh:mm a').format(_now),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(_now),
                style: const TextStyle(color: Color(0xFFC12CFF), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          const Spacer(),
          
          // RIGHT: Search + More
          Row(
            children: [
              _HeaderIconButton(icon: Icons.search_rounded, onTap: () {}),
              const SizedBox(width: 12),
              _HeaderIconButton(icon: Icons.more_vert_rounded, onTap: () {}),
            ],
          ),
        ],
      ),
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
                label: cat.category.categoryName.toUpperCase(),
                count: cat.contentItems.length,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    if (cat.contentItems.isNotEmpty) {
                      _focusedChannel = cat.contentItems.first;
                      _fetchEpg(_focusedChannel!);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChannelPanel() {
    final channels = _selectedCategory?.contentItems ?? [];
    
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _channelScrollController,
            itemCount: channels.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final channel = channels[index];
              final isFocused = _focusedChannel?.id == channel.id;
              
              return _ChannelItem(
                channel: channel,
                index: index + 1,
                isFocused: isFocused,
                onFocus: () => _onChannelFocused(channel),
                onTap: () => navigateByContentType(context, channel),
              );
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
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC12CFF).withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: const Color(0xFFC12CFF).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_focusedChannel!.imagePath.isNotEmpty)
                    Image.network(
                      _focusedChannel!.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(child: Icon(Icons.live_tv, size: 80, color: Colors.white10)),
                    )
                  else
                    const Center(child: Icon(Icons.live_tv, size: 80, color: Colors.white10)),
                  
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
                ],
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
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isFocused ? const Color(0xFFC12CFF) : Colors.white10),
          ),
          child: Icon(widget.icon, color: _isFocused ? Colors.white : Colors.white70, size: 22),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
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
