import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/football_models.dart';
import '../../services/football_data_service.dart';
import '../../services/config_service.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../models/playlist_content_model.dart';
import '../../models/content_type.dart';
import '../../utils/navigate_by_content_type.dart';
import '../../services/app_state.dart';

class SportsHubScreen extends StatefulWidget {
  const SportsHubScreen({super.key});

  @override
  State<SportsHubScreen> createState() => _SportsHubScreenState();
}

class _SportsHubScreenState extends State<SportsHubScreen> {
  final FootballDataService _footballService = FootballDataService();
  bool _isLoading = true;
  List<FootballMatch> _allMatches = [];
  String _selectedSection = 'TODAY';
  
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadData();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // For now we just load today's matches. 
      // In a full implementation we might fetch live, upcoming, and results separately.
      final matches = await _footballService.getTodayMatches();
      if (mounted) {
        setState(() {
          _allMatches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FootballMatch> get _filteredMatches {
    switch (_selectedSection) {
      case 'LIVE':
        return _allMatches.where((m) => m.isLive).toList();
      case 'UPCOMING':
        return _allMatches.where((m) => m.status == 'TIMED' || m.status == 'SCHEDULED').toList();
      case 'RESULTS':
        return _allMatches.where((m) => m.isFinished).toList();
      case 'TODAY':
      default:
        return _allMatches;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>().config;
    final homeBg = config.backgrounds.home;

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
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSectionTabs(),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFC12CFF)))
                    : _buildMatchList(),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/App_Logo.png',
            height: 50,
            fit: BoxFit.contain,
          ),
          const Spacer(),
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
          _HeaderIconButton(icon: Icons.search_rounded, onTap: () {}),
          const SizedBox(width: 12),
          _HeaderIconButton(icon: Icons.more_vert_rounded, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    final sections = ['TODAY', 'LIVE', 'UPCOMING', 'RESULTS'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: sections.map((s) => _SectionTab(
          label: s, 
          isSelected: _selectedSection == s,
          onTap: () => setState(() => _selectedSection = s),
        )).toList(),
      ),
    );
  }

  Widget _buildMatchList() {
    final matches = _filteredMatches;
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No matches found for $_selectedSection',
          style: const TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _MatchCard(match: matches[index]),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powered by football-data.org',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionTab extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectionTab({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_SectionTab> createState() => _SectionTabState();
}

class _SectionTabState extends State<_SectionTab> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || widget.isSelected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FocusableActionDetector(
        onFocusChange: (v) => setState(() => _isFocused = v),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFC12CFF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? const Color(0xFFC12CFF) : Colors.white10, width: 1.5),
              boxShadow: _isFocused ? [
                BoxShadow(color: const Color(0xFFC12CFF).withValues(alpha: 0.3), blurRadius: 10)
              ] : [],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatefulWidget {
  final FootballMatch match;
  const _MatchCard({required this.match});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  bool _isFocused = false;
  List<ContentItem> _matchingChannels = [];
  bool _isCheckingChannels = true;

  @override
  void initState() {
    super.initState();
    _findIptvChannels();
  }

  Future<void> _findIptvChannels() async {
    // Attempt to match IPTV channels
    // This is a simplified matching logic. 
    // In production, we would have a mapping of leagues/teams to common sports channels.
    final repo = AppState.xtreamCodeRepository;
    if (repo == null) {
      setState(() => _isCheckingChannels = false);
      return;
    }

    final sportsKeywords = ['Sky Sports', 'TNT Sports', 'Premier Sports', 'DAZN', 'ESPN', 'BeIN', 'SuperSport', 'Eurosport'];
    
    try {
      final matches = <ContentItem>[];
      
      // Attempt to find coverage by searching for sports provider names
      for (final keyword in sportsKeywords) {
        final searchResults = await repo.searchLiveStreams(keyword, limit: 1);
        if (searchResults.isNotEmpty) {
          matches.addAll(searchResults.map((ls) => ContentItem(
            ls.streamId, 
            ls.name, 
            ls.streamIcon, 
            ContentType.liveStream,
            liveStream: ls,
          )));
        }
      }

      if (mounted) {
        setState(() {
          _matchingChannels = matches;
          _isCheckingChannels = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingChannels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: AnimatedScale(
        scale: _isFocused ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          border: Border.all(
            color: _isFocused ? const Color(0xFFC12CFF) : Colors.white10,
            width: _isFocused ? 2 : 1,
          ),
          child: Row(
            children: [
              // Competition Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.match.competitionName.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF00B7FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.match.status,
                      style: TextStyle(
                        color: widget.match.isLive ? Colors.redAccent : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Teams & Score
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.match.homeTeam.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: widget.match.isLive || widget.match.isFinished
                        ? Text(
                            '${widget.match.score.homeScore ?? 0} - ${widget.match.score.awayScore ?? 0}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          )
                        : Text(
                            DateFormat('HH:mm').format(widget.match.utcDate.toLocal()),
                            style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                    ),
                    Expanded(
                      child: Text(
                        widget.match.awayTeam.name,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Watch Button
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _isCheckingChannels 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : _matchingChannels.isNotEmpty
                      ? _WatchButton(onTap: () => navigateByContentType(context, _matchingChannels.first))
                      : const Text('NO COVERAGE', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchButton extends StatefulWidget {
  final VoidCallback onTap;
  const _WatchButton({required this.onTap});

  @override
  State<_WatchButton> createState() => _WatchButtonState();
}

class _WatchButtonState extends State<_WatchButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused ? [
              BoxShadow(color: const Color(0xFF2575FC).withValues(alpha: 0.4), blurRadius: 15)
            ] : [],
          ),
          child: const Text(
            'WATCH',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
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
