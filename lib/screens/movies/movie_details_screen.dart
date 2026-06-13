import 'dart:ui';
import 'package:another_iptv_player/l10n/localization_extension.dart';
import 'package:another_iptv_player/models/api_configuration_model.dart';
import 'package:another_iptv_player/models/content_type.dart';
import 'package:another_iptv_player/models/playlist_content_model.dart';
import 'package:another_iptv_player/models/watch_history.dart';
import 'package:another_iptv_player/repositories/iptv_repository.dart';
import 'package:another_iptv_player/services/app_state.dart';
import 'package:another_iptv_player/services/watch_history_service.dart';
import 'package:another_iptv_player/shared/widgets/glass_panel.dart';
import 'package:another_iptv_player/shared/widgets/gradient_button.dart';
import 'package:another_iptv_player/shared/widgets/poster_card.dart';
import 'package:another_iptv_player/utils/get_playlist_type.dart';
import 'package:another_iptv_player/screens/player/unified_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/player_widget.dart';

class MovieDetailsScreen extends StatefulWidget {
  final ContentItem contentItem;
  const MovieDetailsScreen({super.key, required this.contentItem});
  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late final WatchHistoryService _watchHistoryService;
  late final IptvRepository? _repository;
  WatchHistory? _watchHistory;
  Map<String, dynamic>? _vodInfo;
  bool _isLoadingHistory = true;
  List<ContentItem> _categoryMovies = [];

  @override
  void initState() {
    super.initState();
    _watchHistoryService = WatchHistoryService();
    if (isXtreamCode && AppState.currentPlaylist != null) {
      _repository = IptvRepository(ApiConfig(baseUrl: AppState.currentPlaylist!.url!, username: AppState.currentPlaylist!.username!, password: AppState.currentPlaylist!.password!), AppState.currentPlaylist!.id);
    } else {
      _repository = null;
    }
    _loadWatchHistory();
    _loadVodInfo();
    _loadCategoryMovies();
  }

  Future<void> _loadCategoryMovies() async {
    try {
      if (isXtreamCode && _repository != null) {
        final vod = widget.contentItem.vodStream;
        final categoryId = vod?.categoryId;
        if (categoryId != null) {
          final movies = await _repository.getMovies(categoryId: categoryId);
          if (movies != null && mounted) setState(() => _categoryMovies = movies.map((x) => ContentItem(x.streamId, x.name, x.streamIcon, ContentType.vod, vodStream: x, containerExtension: x.containerExtension)).toList());
        }
      } else if (isM3u) {
        final categoryId = widget.contentItem.m3uItem?.categoryId;
        if (categoryId != null) {
          final items = await AppState.m3uRepository!.getM3uItemsByCategoryId(categoryId: categoryId, contentType: ContentType.vod);
          if (items != null && mounted) setState(() => _categoryMovies = items.map((x) => ContentItem(x.id, x.name ?? 'NO NAME', x.tvgLogo ?? '', ContentType.vod, m3uItem: x)).toList());
        }
      }
    } catch (e) { debugPrint('Error loading category movies: $e'); }
  }

  Future<void> _loadWatchHistory() async {
    final playlist = AppState.currentPlaylist;
    if (playlist == null) { if (mounted) setState(() { _watchHistory = null; _isLoadingHistory = false; }); return; }
    if (mounted) setState(() => _isLoadingHistory = true);
    try {
      final streamId = isXtreamCode ? widget.contentItem.id : widget.contentItem.m3uItem?.id ?? widget.contentItem.id;
      final history = await _watchHistoryService.getWatchHistory(playlist.id, streamId);
      if (mounted) setState(() { _watchHistory = history; _isLoadingHistory = false; });
    } catch (_) { if (mounted) setState(() { _watchHistory = null; _isLoadingHistory = false; }); }
  }

  Future<void> _loadVodInfo() async {
    if (!isXtreamCode || _repository == null) return;
    try {
      final info = await _repository.getVodInfo(widget.contentItem.id);
      if (mounted) setState(() => _vodInfo = info);
    } catch (_) {}
  }

  double? get _progress {
    final history = _watchHistory;
    if (history?.watchDuration == null || history?.totalDuration == null) return null;
    final total = history!.totalDuration!.inMilliseconds;
    if (total <= 0) return null;
    return (history.watchDuration!.inMilliseconds / total).clamp(0.0, 1.0);
  }

  String? get _posterUrl {
    if (_vodInfo != null) {
      final cover = _vodInfo!['cover_big'] ?? _vodInfo!['cover'];
      if (cover is String && cover.isNotEmpty) return cover;
    }
    return widget.contentItem.coverPath?.isNotEmpty == true ? widget.contentItem.coverPath : widget.contentItem.imagePath.isNotEmpty ? widget.contentItem.imagePath : widget.contentItem.vodStream?.streamIcon;
  }

  String? get _backdropUrl {
    if (_vodInfo != null) {
      final backdrop = _vodInfo!['backdrop_path'];
      if (backdrop is List && backdrop.isNotEmpty) return backdrop.first.toString();
      if (backdrop is String && backdrop.isNotEmpty) return backdrop;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
      ),
      body: Stack(fit: StackFit.expand, children: [
        _buildBackdrop(),
        LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 20, bottom: 40, left: 16, right: 16),
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: _buildModernLayout(context, isDesktop: isDesktop))),
          );
        }),
      ]),
    );
  }

  Widget _buildBackdrop() {
    final url = _backdropUrl ?? _posterUrl;
    if (url == null) return Container(color: Colors.black);
    return Stack(fit: StackFit.expand, children: [
      CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, _, _) => Container(color: Colors.black)),
      BackdropFilter(filter: ImageFilter.blur(sigmaX: _backdropUrl != null ? 5 : 15, sigmaY: _backdropUrl != null ? 5 : 15), child: Container(color: Colors.black.withValues(alpha: 0.5))),
      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2), Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8), Theme.of(context).scaffoldBackgroundColor], stops: const [0.0, 0.4, 0.8, 1.0]))),
    ]);
  }

  Widget _buildModernLayout(BuildContext context, {required bool isDesktop}) {
    final details = _buildMovieInfo(context, centered: !isDesktop);
    final actions = _buildActionPanel(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassPanel(padding: const EdgeInsets.all(16), child: isDesktop ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildPoster(height: 390), const SizedBox(width: 28), Expanded(child: details), const SizedBox(width: 20), SizedBox(width: 230, child: actions),
      ]) : Column(crossAxisAlignment: CrossAxisAlignment.center, children: [_buildPoster(height: 320), const SizedBox(height: 20), details, const SizedBox(height: 20), actions])),
      const SizedBox(height: 22),
      _buildRecommendedCarousel(context),
    ]);
  }

  Widget _buildMovieInfo(BuildContext context, {required bool centered}) {
    final rating = _buildRatingSection(context);
    final chips = _buildInfoChips(context);
    final description = _buildDescriptionSection(context);
    final extra = _buildExtraDetails(context);
    return Column(crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
      _buildTitle(context, textAlign: centered ? TextAlign.center : TextAlign.start),
      const SizedBox(height: 12),
      if (rating != null) ...[rating, const SizedBox(height: 12)],
      if (chips != null) ...[chips, const SizedBox(height: 18)],
      if (description != null) ...[description, const SizedBox(height: 18)],
      ?extra,
    ]);
  }

  Widget _buildActionPanel(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GradientButton(onPressed: _openPlayer, icon: Icons.play_arrow_rounded, child: Text(context.loc.start_watching)),
      const SizedBox(height: 12),
      _buildTrailerButton(context) ?? const SizedBox.shrink(),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _copyShareText, icon: const Icon(Icons.share), label: const Text('Share')),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.download), label: const Text('Download')),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.favorite_border), label: const Text('Favourite')),
      if (!_isLoadingHistory) ...[const SizedBox(height: 18), _buildProgressSummary(context)],
    ]);
  }

  Widget _buildProgressSummary(BuildContext context) {
    final progress = _progress;
    if (progress == null || progress <= 0.01 || _watchHistory == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary), borderRadius: BorderRadius.circular(2)),
      const SizedBox(height: 8),
      Text('${_formatDuration(_watchHistory!.watchDuration!)} / ${_formatDuration(_watchHistory!.totalDuration!)}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
    ]);
  }

  Widget _buildRecommendedCarousel(BuildContext context) {
    final items = _categoryMovies.where((item) => item.id != widget.contentItem.id).take(12).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return GlassPanel(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('You May Also Like', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      SizedBox(height: 220, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, _) => const SizedBox(width: 12), itemBuilder: (context, index) {
        final item = items[index];
        return SizedBox(width: 126, child: PosterCard(title: item.name, imageUrl: item.coverPath ?? item.imagePath, subtitle: item.vodStream?.genre, rating: item.vodStream?.rating.isNotEmpty == true ? item.vodStream!.rating : null, onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MovieDetailsScreen(contentItem: item)))));
      })),
    ]));
  }

  Widget _buildPoster({required double height}) {
    final url = _posterUrl;
    if (url == null) return const SizedBox.shrink();
    return Container(height: height, width: height * 0.66, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (context, url) => Container(color: Colors.grey.shade900, child: const Center(child: CircularProgressIndicator())), errorWidget: (context, url, error) => Container(color: Colors.grey.shade900, child: const Icon(Icons.movie, size: 50, color: Colors.grey)))),
    );
  }

  Widget _buildTitle(BuildContext context, {required TextAlign textAlign}) {
    return Text(widget.contentItem.name, textAlign: textAlign, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.5), offset: const Offset(0, 2))]));
  }

  Widget? _buildRatingSection(BuildContext context) {
    final vod = widget.contentItem.vodStream;
    if (vod == null) return null;
    String? label;
    final parsedRating = double.tryParse(vod.rating.trim());
    if (parsedRating != null && parsedRating > 0) { label = '${parsedRating % 1 == 0 ? parsedRating.toStringAsFixed(0) : parsedRating.toStringAsFixed(1)}/10'; }
    else if (vod.rating5based > 0) { label = '${vod.rating5based % 1 == 0 ? vod.rating5based.toStringAsFixed(0) : vod.rating5based.toStringAsFixed(1)}/5'; }
    if (label == null) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star_rounded, color: Colors.amber.shade500, size: 28), const SizedBox(width: 8), Text(label, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white))]);
  }

  Widget? _buildInfoChips(BuildContext context) {
    final chips = <Widget>[];
    final duration = _vodInfo?['duration'] ?? widget.contentItem.duration?.inSeconds;
    if (duration is int && duration > 0) chips.add(_InfoChip(icon: Icons.access_time, label: _formatDuration(Duration(seconds: duration))));
    final genre = widget.contentItem.vodStream?.genre ?? _vodInfo?['genre'];
    if (genre is String && genre.trim().isNotEmpty) chips.add(_InfoChip(icon: Icons.local_movies, label: genre.trim()));
    final format = (widget.contentItem.containerExtension ?? widget.contentItem.vodStream?.containerExtension)?.trim();
    if (format != null && format.isNotEmpty) chips.add(_InfoChip(icon: Icons.sd_card, label: format.toUpperCase()));
    final releaseDate = _vodInfo?['releaseDate'] ?? _vodInfo?['release_date'] ?? _vodInfo?['year'];
    if (releaseDate is String && releaseDate.trim().isNotEmpty) chips.add(_InfoChip(icon: Icons.calendar_today, label: releaseDate.trim()));
    if (chips.isEmpty) return null;
    return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: chips);
  }

  Widget? _buildDescriptionSection(BuildContext context) {
    final description = _vodInfo?['plot'] ?? widget.contentItem.description?.trim();
    if (description == null || description.isEmpty) return null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.loc.description, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white70)), const SizedBox(height: 8), Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.5))]);
  }

  Widget? _buildExtraDetails(BuildContext context) {
    final entries = <_DetailEntry>[];
    final director = _vodInfo?['director'];
    if (director is String && director.isNotEmpty) entries.add(_DetailEntry(icon: Icons.person, title: context.loc.director, value: director));
    final cast = _vodInfo?['cast'];
    if (cast is String && cast.isNotEmpty) entries.add(_DetailEntry(icon: Icons.people, title: context.loc.cast, value: cast));
    if (entries.isEmpty) return null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.loc.info, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white70)), const SizedBox(height: 12), Wrap(spacing: 12, runSpacing: 12, children: entries.map((e) => _DetailCard(icon: e.icon, title: e.title, value: e.value)).toList())]);
  }

  Widget? _buildTrailerButton(BuildContext context) {
    if (widget.contentItem.name.isEmpty) return null;
    return FilledButton.tonalIcon(onPressed: () => _openTrailer(context), icon: const Icon(Icons.ondemand_video), label: Text(context.loc.trailer), style: FilledButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.2), foregroundColor: Colors.white));
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final buffer = StringBuffer();
    if (hours > 0) buffer.write('${hours.toString().padLeft(2, '0')}:');
    buffer.write('${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');
    return buffer.toString();
  }

  Future<void> _openTrailer(BuildContext context) async {
    final trailerKey = widget.contentItem.vodStream?.youtubeTrailer ?? _vodInfo?['youtube_trailer'];
    final urlString = (trailerKey is String && trailerKey.isNotEmpty) ? 'https://www.youtube.com/watch?v=$trailerKey' : 'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent('${widget.contentItem.name} trailer')}';
    try { await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.error_occurred_title))); }
  }

  Future<void> _copyShareText() async { await Clipboard.setData(ClipboardData(text: widget.contentItem.name)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'))); }

  void _openPlayer() { 
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnifiedPlayerScreen(
          contentItem: widget.contentItem, 
          queue: _categoryMovies.isNotEmpty ? _categoryMovies : [widget.contentItem]
        )
      )
    ); 
  }
}

class _DetailEntry { final IconData icon; final String title; final String value; _DetailEntry({required this.icon, required this.title, required this.value}); }

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.white70), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13))]));
}

class _DetailCard extends StatelessWidget {
  final IconData icon; final String title; final String value;
  const _DetailCard({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white70, size: 20), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)), const SizedBox(height: 2), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))])]));
}

