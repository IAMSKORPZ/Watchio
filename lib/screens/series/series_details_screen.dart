import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:another_iptv_player/database/database.dart';
import 'package:another_iptv_player/models/api_configuration_model.dart';
import 'package:another_iptv_player/models/content_type.dart';
import 'package:another_iptv_player/models/playlist_content_model.dart';
import 'package:another_iptv_player/services/app_state.dart';
import 'package:another_iptv_player/repositories/iptv_repository.dart';
import 'package:another_iptv_player/l10n/localization_extension.dart';
import 'package:another_iptv_player/shared/widgets/glass_panel.dart';
import 'package:another_iptv_player/shared/widgets/gradient_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:another_iptv_player/services/watch_history_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../controllers/favorites_controller.dart';
import 'episode_screen.dart';

class SeriesDetailsScreen extends StatefulWidget {
  final ContentItem contentItem;

  const SeriesDetailsScreen({super.key, required this.contentItem});

  @override
  State<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> with SingleTickerProviderStateMixin {
  late IptvRepository _repository;
  late FavoritesController _favoritesController;
  late WatchHistoryService _watchHistoryService;
  late TabController _tabController;

  SeriesInfosData? seriesInfo;
  List<SeasonsData> seasons = [];
  List<EpisodesData> episodes = [];
  bool isLoading = true;
  String? error;
  bool _isFavorite = false;
  
  SeasonsData? _selectedSeason;
  EpisodesData? _lastOpenedEpisode;

  final FocusNode _playFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoritesController = FavoritesController();
    _watchHistoryService = WatchHistoryService();
    _initializeRepository();
    _loadSeriesDetails();
    _checkFavoriteStatus();
  }

  void _initializeRepository() {
    _repository = IptvRepository(
      ApiConfig(
        baseUrl: AppState.currentPlaylist!.url!,
        username: AppState.currentPlaylist!.username!,
        password: AppState.currentPlaylist!.password!,
      ),
      AppState.currentPlaylist!.id,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _playFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSeriesDetails() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final seriesId = widget.contentItem.id;
      final seriesResponse = await _repository.getSeriesInfo(seriesId);

      if (seriesResponse != null && mounted) {
        setState(() {
          seriesInfo = seriesResponse.seriesInfo;
          seasons = seriesResponse.seasons;
          episodes = seriesResponse.episodes;
          if (seasons.isNotEmpty) {
            _selectedSeason = seasons.first;
          }
          isLoading = false;
        });
        await _loadLastOpenedEpisodeFromHistory();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playFocusNode.requestFocus();
        });
      } else if (mounted) {
        setState(() {
          error = context.loc.preparing_series_exception_1;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = context.loc.preparing_series_exception_2(e.toString());
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLastOpenedEpisodeFromHistory() async {
    if (episodes.isEmpty) return;
    final playlistId = AppState.currentPlaylist!.id;
    final allSeriesHistory = await _watchHistoryService
        .getWatchHistoryByContentType(ContentType.series, playlistId);

    if (!mounted || allSeriesHistory.isEmpty) return;

    final Map<String, EpisodesData> byId = {
      for (final ep in episodes) ep.episodeId.toString(): ep,
    };

    EpisodesData? matched;
    for (final history in allSeriesHistory) {
      final ep = byId[history.streamId];
      if (ep != null) {
        matched = ep;
        break;
      }
    }

    if (matched != null && mounted) {
      setState(() {
        _lastOpenedEpisode = matched;
        for (var s in seasons) {
           if (s.seasonNumber == matched!.season) {
             _selectedSeason = s;
             break;
           }
        }
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await _favoritesController.isFavorite(
      widget.contentItem.id,
      widget.contentItem.contentType,
    );
    if (mounted) {
      setState(() => _isFavorite = isFavorite);
    }
  }

  Future<void> _toggleFavorite() async {
    final result = await _favoritesController.toggleFavorite(widget.contentItem);
    if (mounted) {
      setState(() => _isFavorite = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? context.loc.added_to_favorites : context.loc.removed_from_favorites),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC12CFF),
        ),
      );
    }
  }

  void _openEpisode(EpisodesData episode) {
    if (mounted) setState(() => _lastOpenedEpisode = episode);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EpisodeScreen(
          seriesInfo: seriesInfo,
          seasons: seasons,
          episodes: episodes,
          contentItem: ContentItem(
            episode.episodeId,
            episode.title,
            episode.movieImage ?? "",
            ContentType.series,
            containerExtension: episode.containerExtension,
            season: episode.season,
          ),
        ),
      ),
    );
  }

  String? get _posterUrl {
    return seriesInfo?.cover ?? widget.contentItem.seriesStream?.cover ?? widget.contentItem.imagePath;
  }

  String? get _backdropUrl {
    if (seriesInfo?.backdropPath != null && seriesInfo!.backdropPath!.isNotEmpty) {
      return seriesInfo!.backdropPath;
    }
    final paths = widget.contentItem.seriesStream?.backdropPath;
    if (paths != null && paths.isNotEmpty) {
      return paths.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050812),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC12CFF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050812),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final content = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      _buildTopSection(isWide),
                      const SizedBox(height: 16),
                      _buildTabsSection(),
                    ],
                  ),
                );

                if (!isWide) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: content,
                  );
                }

                return content;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop() {
    final url = _backdropUrl ?? _posterUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          CachedNetworkImage(
            imageUrl: url, 
            fit: BoxFit.cover, 
            errorWidget: (ctx, err, st) => Container(color: Colors.black)
          )
        else
          Container(color: Colors.black),
        
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withValues(alpha: 0.7)),
        ),
        
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF050812).withValues(alpha: 0.8),
                const Color(0xFF050812),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSection(bool isWide) {
    if (!isWide) {
      return Column(
        children: [
          _buildPosterColumn(),
          const SizedBox(height: 20),
          _buildMetadataColumn(),
          const SizedBox(height: 20),
          _buildActionsColumn(),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 200, child: _buildPosterColumn()),
          const SizedBox(width: 32),
          Expanded(child: _buildMetadataColumn()),
          const SizedBox(width: 32),
          SizedBox(width: 220, child: _buildActionsColumn()),
        ],
      ),
    );
  }

  Widget _buildPosterColumn() {
    final url = _posterUrl;
    final rating = seriesInfo?.rating5based?.toStringAsFixed(1) ?? '';
    final year = seriesInfo?.releaseDate?.split('-').first ?? '';

    return Column(
      children: [
        Hero(
          tag: 'series_poster_${widget.contentItem.id}',
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC12CFF).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: url != null 
                ? CachedNetworkImage(
                    imageUrl: url, 
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(color: Colors.white10),
                    errorWidget: (ctx, url, err) => _buildPlaceholderPoster(),
                  )
                : _buildPlaceholderPoster(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (rating.isNotEmpty && rating != '0.0')
              _MiniBadge(text: '★ $rating', color: Colors.amber),
            if (year.isNotEmpty) _MiniBadge(text: year),
            _MiniBadge(text: '${seasons.length} SEASONS'),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderPoster() {
    return AspectRatio(
      aspectRatio: 2/3,
      child: Container(
        color: Colors.white10,
        child: const Icon(Icons.tv_rounded, size: 40, color: Colors.white24),
      ),
    );
  }

  Widget _buildMetadataColumn() {
    final title = seriesInfo?.name ?? widget.contentItem.name;
    final genre = seriesInfo?.genre ?? widget.contentItem.seriesStream?.genre ?? '';
    final plot = seriesInfo?.plot ?? widget.contentItem.seriesStream?.plot ?? '';
    final director = seriesInfo?.director ?? '';
    final castString = seriesInfo?.cast ?? widget.contentItem.seriesStream?.cast ?? '';
    final castList = castString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.1),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (genre.isNotEmpty)
          Text(
            genre.toUpperCase(),
            style: const TextStyle(color: Color(0xFF00B7FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
          ),
        const SizedBox(height: 12),
        Text(
          plot,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          maxLines: 3, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        if (director.isNotEmpty)
          _buildInfoRow('Director', director),
        if (castList.isNotEmpty)
          _buildInfoRow('Main Cast', castList.join(', ')),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        maxLines: 1, overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
            TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsColumn() {
    final hasLastPlayed = _lastOpenedEpisode != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(
          focusNode: _playFocusNode,
          onPressed: () {
            if (hasLastPlayed) {
              _openEpisode(_lastOpenedEpisode!);
            } else if (episodes.isNotEmpty) {
              _openEpisode(episodes.first);
            }
          }, 
          icon: Icons.play_arrow_rounded, 
          child: Text(
            (hasLastPlayed ? context.loc.continue_watching : context.loc.start_watching).toUpperCase(), 
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12)
          )
        ),
        const SizedBox(height: 10),
        _buildActionBtn(
          label: context.loc.trailer.toUpperCase(),
          icon: Icons.ondemand_video_rounded,
          onTap: () => _openTrailer(context),
        ),
        const SizedBox(height: 10),
        _buildActionBtn(
          label: _isFavorite ? 'REMOVE FAV' : 'FAVOURITE',
          icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: _isFavorite ? Colors.redAccent : null,
          onTap: _toggleFavorite,
        ),
        const SizedBox(height: 10),
        _buildActionBtn(
          label: 'WATCHLIST',
          icon: Icons.bookmark_add_outlined,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionBtn({required String label, required IconData icon, required VoidCallback onTap, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFFC12CFF),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13),
            tabs: const [
              Tab(text: 'EPISODES'),
              Tab(text: 'CAST'),
              Tab(text: 'SIMILAR'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEpisodesTab(),
                _buildCastTab(),
                _buildSimilarTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab() {
    final filteredEpisodes = episodes.where((e) => e.season == _selectedSeason?.seasonNumber).toList();

    return Column(
      children: [
        Row(
          children: [
            const Text('SEASON', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 12),
            Theme(
              data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1A1D29)),
              child: DropdownButton<SeasonsData>(
                value: _selectedSeason,
                underline: const SizedBox(),
                items: seasons.map((s) => DropdownMenuItem(
                  value: s, 
                  child: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSeason = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: filteredEpisodes.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ep = filteredEpisodes[index];
              return _EpisodeListTile(
                episode: ep,
                onTap: () => _openEpisode(ep),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCastTab() {
    final castString = seriesInfo?.cast ?? widget.contentItem.seriesStream?.cast ?? '';
    if (castString.isEmpty) return Center(child: Text(context.loc.not_found_in_category, style: const TextStyle(color: Colors.white24)));
    final castList = castString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: castList.length,
      separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
      itemBuilder: (context, index) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
          child: Text(castList[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildSimilarTab() {
    return Center(child: Text(context.loc.not_found_in_category, style: const TextStyle(color: Colors.white24)));
  }

  Future<void> _openTrailer(BuildContext context) async {
    final trailerKey = seriesInfo?.youtubeTrailer;
    final urlString = (trailerKey != null && trailerKey.isNotEmpty)
        ? "https://www.youtube.com/watch?v=$trailerKey"
        : "https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent("${widget.contentItem.name} trailer")}";
    try { await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication); } catch (_) {}
  }
}

class _EpisodeListTile extends StatelessWidget {
  final EpisodesData episode;
  final VoidCallback onTap;

  const _EpisodeListTile({required this.episode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassPanel(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFFC12CFF).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFC12CFF), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EPISODE ${episode.episodeNum}', style: const TextStyle(color: Color(0xFF00B7FF), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(episode.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            if (episode.duration != null && episode.duration!.isNotEmpty)
              Text(episode.duration!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color? color;
  const _MiniBadge({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: (color ?? Colors.white).withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color ?? Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
