import 'package:another_iptv_player/models/api_response.dart';
import 'package:flutter/material.dart';
import 'package:another_iptv_player/l10n/localization_extension.dart';
import 'package:another_iptv_player/models/category.dart';
import 'package:another_iptv_player/models/category_type.dart';
import 'package:another_iptv_player/models/category_view_model.dart';
import 'package:another_iptv_player/models/content_type.dart';
import 'package:another_iptv_player/models/playlist_content_model.dart';
import 'package:another_iptv_player/repositories/iptv_repository.dart';
import 'package:another_iptv_player/services/app_state.dart';
import '../repositories/user_preferences.dart';
import '../screens/xtream-codes/xtream_code_data_loader_screen.dart';

class XtreamCodeHomeController extends ChangeNotifier {
  late PageController _pageController;
  final IptvRepository? _repository;

  ApiResponse? _userInfo;
  int _currentIndex = 0;
  bool _isLoading = false;

  final List<CategoryViewModel> _liveCategories = [];
  final List<CategoryViewModel> _movieCategories = [];
  final List<CategoryViewModel> _seriesCategories = [];

  final Set<String> _hiddenMovieCategoryIds = {};
  final Set<String> _hiddenSeriesCategoryIds = {};

  ApiResponse? get userInfo => _userInfo;
  Set<String> get hiddenMovieCategoryIds => _hiddenMovieCategoryIds;
  Set<String> get hiddenSeriesCategoryIds => _hiddenSeriesCategoryIds;

  void toggleMovieCategoryVisibility(String categoryId) {
    if (_hiddenMovieCategoryIds.contains(categoryId)) {
      _hiddenMovieCategoryIds.remove(categoryId);
    } else {
      _hiddenMovieCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  void toggleSeriesCategoryVisibility(String categoryId) {
    if (_hiddenSeriesCategoryIds.contains(categoryId)) {
      _hiddenSeriesCategoryIds.remove(categoryId);
    } else {
      _hiddenSeriesCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  List<CategoryViewModel> get visibleMovieCategories => _movieCategories
      .where((c) => !_hiddenMovieCategoryIds.contains(c.category.categoryId))
      .toList();

  List<CategoryViewModel> get visibleSeriesCategories => _seriesCategories
      .where((c) => !_hiddenSeriesCategoryIds.contains(c.category.categoryId))
      .toList();

  PageController get pageController => _pageController;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  List<CategoryViewModel>? get liveCategories => _liveCategories;
  List<CategoryViewModel> get movieCategories => _movieCategories;
  List<CategoryViewModel> get seriesCategories => _seriesCategories;

  XtreamCodeHomeController(bool all) : _repository = AppState.xtreamCodeRepository {
    _pageController = PageController();
    _loadCategories(all);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onNavigationTap(int index) {
    _currentIndex = index;
    notifyListeners();
    if (_pageController.hasClients) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  String getPageTitle(BuildContext context) {
    try {
      switch (currentIndex) {
        case 0: return context.loc.home;
        case 1: return context.loc.history;
        case 2: return context.loc.live_streams;
        case 3: return context.loc.movies;
        case 4: return context.loc.series_plural;
        case 5: return context.loc.settings;
        default: return 'Watchio IPTV';
      }
    } catch (_) { return 'Watchio IPTV'; }
  }

  Future<void> _loadCategories(bool all) async {
    if (_repository == null) return;
    try {
      _isLoading = true;
      notifyListeners();
      _userInfo = await _repository.getPlayerInfo();

      // Prepend virtual categories
      _addVirtualCategories(CategoryType.live, _liveCategories);
      _addVirtualCategories(CategoryType.vod, _movieCategories);
      _addVirtualCategories(CategoryType.series, _seriesCategories);
      
      final liveCats = await _repository.getLiveCategories();
      if (liveCats != null) {
        for (var cat in liveCats) {
          final streams = await _repository.getLiveChannelsByCategoryId(categoryId: cat.categoryId, top: 10);
          if (streams == null || streams.isEmpty) continue;
          final vm = CategoryViewModel(category: cat, contentItems: streams.map((x) => ContentItem(x.streamId, x.name, x.streamIcon, ContentType.liveStream, liveStream: x)).toList());
          if (!all) { if (!await UserPreferences.getHiddenCategory(cat.categoryId)) _liveCategories.add(vm); }
          else {
            _liveCategories.add(vm);
          }
        }
      }
      
      final movieCats = await _repository.getVodCategories();
      if (movieCats != null) {
        for (var cat in movieCats) {
          final movies = await _repository.getMovies(categoryId: cat.categoryId, top: 10);
          if (movies == null || movies.isEmpty) continue;
          final vm = CategoryViewModel(category: cat, contentItems: movies.map((x) => ContentItem(x.streamId, x.name, x.streamIcon, ContentType.vod, containerExtension: x.containerExtension, vodStream: x)).toList());
          if (!all) { if (!await UserPreferences.getHiddenCategory(cat.categoryId)) _movieCategories.add(vm); }
          else {
            _movieCategories.add(vm);
          }
        }
      }
      
      final seriesCats = await _repository.getSeriesCategories();
      if (seriesCats != null) {
        for (var cat in seriesCats) {
          final series = await _repository.getSeries(categoryId: cat.categoryId, top: 10);
          if (series == null || series.isEmpty) continue;
          final vm = CategoryViewModel(category: cat, contentItems: series.map((x) => ContentItem(x.seriesId, x.name, x.cover ?? '', ContentType.series, seriesStream: x)).toList());
          if (!all) { if (!await UserPreferences.getHiddenCategory(cat.categoryId)) _seriesCategories.add(vm); }
          else {
            _seriesCategories.add(vm);
          }
        }
      }
    } catch (e) { debugPrint(e.toString()); }
    finally { _isLoading = false; notifyListeners(); }
  }

  void _addVirtualCategories(CategoryType type, List<CategoryViewModel> list) {
    final playlistId = AppState.currentPlaylist?.id ?? '';
    
    // 1. All
    list.add(CategoryViewModel(
      category: Category(
        categoryId: IptvRepository.virtualAll, 
        categoryName: _getAllLabel(type), 
        parentId: 0, 
        playlistId: playlistId, 
        type: type
      ), 
      contentItems: []
    ));
    
    // 2. Favorites
    list.add(CategoryViewModel(
      category: Category(
        categoryId: IptvRepository.virtualFavorites, 
        categoryName: 'FAVOURITES', 
        parentId: 0, 
        playlistId: playlistId, 
        type: type
      ), 
      contentItems: []
    ));
    
    // 3. History
    list.add(CategoryViewModel(
      category: Category(
        categoryId: IptvRepository.virtualHistory, 
        categoryName: 'HISTORY',
        parentId: 0, 
        playlistId: playlistId, 
        type: type
      ), 
      contentItems: []
    ));
  }

  String _getAllLabel(CategoryType type) {
    switch (type) {
      case CategoryType.live: return 'ALL CHANNELS';
      case CategoryType.vod: return 'ALL MOVIES';
      case CategoryType.series: return 'ALL SERIES';
    }
  }

  void refresh() => notifyListeners();

  Future<List<ContentItem>> getCategoryItems(Category category, {int top = 60, int offset = 0}) async {
    if (_repository == null) return [];
    
    switch (category.type) {
      case CategoryType.live:
        final streams = await _repository.getLiveChannelsByCategoryId(categoryId: category.categoryId, top: top, offset: offset);
        return streams?.map((x) => ContentItem(x.streamId, x.name, x.streamIcon, ContentType.liveStream, liveStream: x)).toList() ?? [];
      case CategoryType.vod:
        final movies = await _repository.getMovies(categoryId: category.categoryId, top: top, offset: offset);
        return movies?.map((x) => ContentItem(x.streamId, x.name, x.streamIcon, ContentType.vod, containerExtension: x.containerExtension, vodStream: x)).toList() ?? [];
      case CategoryType.series:
        final series = await _repository.getSeries(categoryId: category.categoryId, top: top, offset: offset);
        return series?.map((x) => ContentItem(x.seriesId, x.name, x.cover ?? '', ContentType.series, seriesStream: x)).toList() ?? [];
    }
  }

  Future<int> getCategoryItemCount(Category category) async {
    if (_repository == null) return 0;
    return await _repository.getItemCountByCategory(category.categoryId, category.type);
  }

  Future<Map<String, int>> getAllCategoryCounts(CategoryType type) async {
    if (_repository == null) return {};
    return await _repository.getAllCategoryCounts(type);
  }

  void refreshAllData(BuildContext context) {
    if (AppState.currentPlaylist == null) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => XtreamCodeDataLoaderScreen(playlist: AppState.currentPlaylist!, refreshAll: true)));
  }
}
