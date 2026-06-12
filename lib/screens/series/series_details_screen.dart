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
import '../../../controllers/favorites_controller.dart';
import 'episode_screen.dart';

class SeriesDetailsScreen extends StatefulWidget {
  final ContentItem contentItem;

  const SeriesDetailsScreen({super.key, required this.contentItem});

  @override
  State<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> {
  late IptvRepository _repository;
  late FavoritesController _favoritesController;
  late WatchHistoryService _watchHistoryService;

  SeriesInfosData? seriesInfo;
  List<SeasonsData> seasons = [];
  List<EpisodesData> episodes = [];
  bool isLoading = true;
  String? error;
  bool _isFavorite = false;

  // Last opened episode for this series (for Continue Watching button)
  EpisodesData? _lastOpenedEpisode;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _favoritesController = FavoritesController();
    _watchHistoryService = WatchHistoryService();
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
          isLoading = false;
        });
        await _loadLastOpenedEpisodeFromHistory();
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
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await _favoritesController.isFavorite(
      widget.contentItem.id,
      widget.contentItem.contentType,
    );
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final result = await _favoritesController.toggleFavorite(widget.contentItem);
    if (mounted) {
      setState(() {
        _isFavorite = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ? context.loc.added_to_favorites : context.loc.removed_from_favorites)),
      );
    }
  }

  void _openEpisodeFromSeries(EpisodesData episode) {
    if (mounted) {
      setState(() {
        _lastOpenedEpisode = episode;
      });
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackdrop(),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.loc.preparing_series),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(fontSize: 16, color: Colors.red.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadSeriesDetails, child: Text(context.loc.try_again)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPoster(),
                              const SizedBox(width: 28),
                              Expanded(child: _buildSeriesHeroInfo()),
                              const SizedBox(width: 20),
                              SizedBox(width: 230, child: _buildSeriesActions()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPoster(),
                              const SizedBox(height: 20),
                              _buildSeriesHeroInfo(centered: true),
                              const SizedBox(height: 20),
                              _buildSeriesActions(),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  _buildSeriesTabs(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackdrop() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCoverImage(),
        Container(color: Colors.black.withValues(alpha: 0.58)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoster() {
    final imageUrl = seriesInfo?.cover ?? widget.contentItem.seriesStream?.cover;
    return SizedBox(
      width: 230,
      height: 345,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl == null || imageUrl.isEmpty
            ? _buildPlaceholder()
            : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder()),
      ),
    );
  }

  Widget _buildSeriesHeroInfo({bool centered = false}) {
    final title = seriesInfo?.name ?? widget.contentItem.name;
    final plot = seriesInfo?.plot ?? widget.contentItem.seriesStream?.plot;
    final genre = seriesInfo?.genre ?? widget.contentItem.seriesStream?.genre;

    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildRatingSection(),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _InfoPill(Icons.layers, '${seasons.length} Seasons'),
            if (episodes.isNotEmpty) _InfoPill(Icons.playlist_play, '${episodes.length} Episodes'),
            if (genre != null && genre.isNotEmpty) _InfoPill(Icons.local_movies, genre),
          ],
        ),
        if (plot != null && plot.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(plot, maxLines: 5, overflow: TextOverflow.ellipsis,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.5)),
        ],
      ],
    );
  }

  Widget _buildSeriesActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(
          onPressed: _lastOpenedEpisode != null
              ? () => _openEpisodeFromSeries(_lastOpenedEpisode!)
              : _openLatestEpisode,
          icon: Icons.play_arrow_rounded,
          child: Text(_lastOpenedEpisode != null ? context.loc.continue_watching : 'Play Latest Episode'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: seasons.isEmpty ? null : _showSeasonPicker,
          icon: const Icon(Icons.view_list),
          label: const Text('Select Season'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openTrailer(context),
          icon: const Icon(Icons.ondemand_video),
          label: Text(context.loc.trailer),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _toggleFavorite,
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          label: const Text('Favourite'),
        ),
      ],
    );
  }

  Widget _buildSeriesTabs() {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [Tab(text: 'Episodes'), Tab(text: 'Cast'), Tab(text: 'Similar Shows')],
            ),
            SizedBox(
              height: 360,
              child: TabBarView(
                children: [
                  SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildSeasonsSection()),
                  SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildCastGrid()),
                  Center(child: Text(context.loc.not_found_in_category)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCastGrid() {
    final cast = seriesInfo?.cast ?? widget.contentItem.seriesStream?.cast;
    final names = cast?.split(',').map((name) => name.trim()).where((name) => name.isNotEmpty).take(12).toList();
    if (names == null || names.isEmpty) {
      return Center(child: Text(context.loc.not_found_in_category));
    }
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: names.map((name) => GlassPanel(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Text(name))).toList(),
    );
  }

  void _openLatestEpisode() {
    if (episodes.isEmpty) return;
    _openEpisodeFromSeries(episodes.last);
  }

  Widget _buildRatingSection() {
    final rating = seriesInfo?.rating5based ?? 0;
    final ratingText = widget.contentItem.seriesStream?.rating5based?.toStringAsFixed(1) ?? '0.0';

    return Row(
      children: [
        ...List.generate(5, (index) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 24),
        )),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('$ratingText/5', style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.tv, size: 64, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Text('Görsel Bulunamadı', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(seriesInfo?.name ?? widget.contentItem.name, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonsSection() {
    final validSeasons = seasons.where((season) => episodes.any((episode) => episode.season == season.seasonNumber)).toList();
    if (validSeasons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
        child: Row(children: [Icon(Icons.info_outline, color: Colors.grey.shade600), const SizedBox(width: 12), Text(context.loc.not_found_in_category)]),
      );
    }
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: validSeasons.length,
        itemBuilder: (context, index) => _buildSeasonCard(validSeasons[index], index),
      ),
    );
  }

  Widget _buildSeasonCard(SeasonsData season, int index) {
    final int realEpisodeCount = episodes.where((e) => e.season == season.seasonNumber).length;
    return Container(
      width: 200, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSeasonEpisodes(season),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.play_circle_outline, size: 20, color: Theme.of(context).primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(season.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(context.loc.episode_count(realEpisodeCount.toString()), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                if (season.airDate != null) ...[const SizedBox(height: 4), Text(season.airDate!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSeasonPicker() {
    final validSeasons = seasons.where((season) => episodes.any((episode) => episode.season == season.seasonNumber)).toList();
    if (validSeasons.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, color: Theme.of(context).colorScheme.primary, size: 30),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.loc.season, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    itemCount: validSeasons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final season = validSeasons[index];
                      final count = episodes.where((e) => e.season == season.seasonNumber).length;
                      return _SeasonPickerRow(title: season.name, subtitle: context.loc.episode_count(count.toString()), selected: index == 0, onTap: () { Navigator.pop(context); _showSeasonEpisodes(season); });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text('Close')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSeasonEpisodes(SeasonsData season) async {
    final int realEpisodeCount = episodes.where((e) => e.season == season.seasonNumber).length;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(season.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                    Text(context.loc.episode_count(realEpisodeCount.toString()), style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<EpisodesData>>(
                  future: _repository.getSeriesEpisodesBySeason(seriesInfo?.seriesId ?? widget.contentItem.id.toString(), season.seasonNumber),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final episodes = snapshot.data ?? [];
                    if (episodes.isEmpty) return Center(child: Text(context.loc.not_found_in_category));
                    return ListView.builder(
                      controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: episodes.length,
                      itemBuilder: (context, index) => _buildEpisodeCard(episodes[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeCard(EpisodesData episode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () { Navigator.pop(context); _openEpisodeFromSeries(episode); },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60, decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: episode.movieImage != null && episode.movieImage!.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(episode.movieImage!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Center(child: Text('${episode.episodeNum}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)))))
                    : Center(child: Text('${episode.episodeNum}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (episode.duration != null && episode.duration!.isNotEmpty) ...[const SizedBox(height: 4), Text(context.loc.duration(episode.duration!), style: TextStyle(fontSize: 12, color: Colors.grey.shade600))],
              ])),
              Icon(Icons.play_circle_outline, color: Theme.of(context).primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) => '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';

  Future<void> _openTrailer(BuildContext context) async {
    final trailerKey = seriesInfo?.youtubeTrailer;
    final String urlString = (trailerKey != null && trailerKey.isNotEmpty)
        ? "https://www.youtube.com/watch?v=$trailerKey"
        : "https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent("${widget.contentItem.name} trailer")}";
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.error_occurred_title)));
    }
  }

  Widget _buildCoverImage() {
    final imageUrl = seriesInfo?.backdropPath ?? seriesInfo?.cover ?? widget.contentItem.seriesStream?.backdropPath?.firstOrNull ?? widget.contentItem.seriesStream?.cover;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder());
    }
    return _buildPlaceholder();
  }

  Widget _buildDetailCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill(this.icon, this.label);
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.white70), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white))])));
}

class _SeasonPickerRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _SeasonPickerRow({required this.title, required this.subtitle, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: DecoratedBox(decoration: BoxDecoration(gradient: selected ? LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.cyan]) : null, color: selected ? null : Colors.white.withValues(alpha: 0.06), border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white70))])), if (selected) const Icon(Icons.check_circle, color: Colors.white) else const Icon(Icons.chevron_right, color: Colors.white70)]))));
}
