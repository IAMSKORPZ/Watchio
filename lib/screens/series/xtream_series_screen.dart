import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/xtream_code_home_controller.dart';
import '../../models/category_type.dart';
import '../../models/category_view_model.dart';
import '../../models/playlist_content_model.dart';
import '../../models/content_type.dart';
import '../../repositories/iptv_repository.dart';
import '../../services/config_service.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../shared/widgets/sidebar_item.dart';
import '../../shared/widgets/poster_card.dart';
import '../../shared/widgets/watchio_header.dart';
import '../../utils/navigate_by_content_type.dart';
import '../../utils/responsive_helper.dart';
import '../search_screen.dart';

class XtreamSeriesScreen extends StatefulWidget {
  const XtreamSeriesScreen({super.key});

  @override
  State<XtreamSeriesScreen> createState() => _XtreamSeriesScreenState();
}

class _XtreamSeriesScreenState extends State<XtreamSeriesScreen> {
  CategoryViewModel? _selectedCategory;
  final List<ContentItem> _currentItems = [];
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 60;
  final Map<String, int> _categoryCounts = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<XtreamCodeHomeController>(
        context,
        listen: false,
      );
      if (controller.seriesCategories.isNotEmpty) {
        // Load counts in bulk
        final counts = await controller.getAllCategoryCounts(
          CategoryType.series,
        );
        if (mounted) {
          setState(() {
            _categoryCounts.addAll(counts);
            _onCategorySelected(controller.seriesCategories.first);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
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
    });

    await _loadMoreItems();
  }

  Future<void> _loadMoreItems() async {
    if (_selectedCategory == null) return;

    setState(() => _isMoreLoading = true);

    try {
      final controller = Provider.of<XtreamCodeHomeController>(
        context,
        listen: false,
      );
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

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>().config;
    final homeBg = config.backgrounds.home;

    return Consumer<XtreamCodeHomeController>(
      builder: (context, controller, child) {
        if (controller.seriesCategories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final deviceType = ResponsiveHelper.getDeviceType(context);
        final isDesktop = deviceType == DeviceType.desktop;

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
                    : const AssetImage('assets/images/background.png')
                          as ImageProvider,
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
                  WatchioHeader(
                    isCompact: true,
                    onBack: () => controller.onNavigationTap(0),
                    onSearch: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SearchScreen(contentType: ContentType.series),
                      ),
                    ),
                    onSettings: () => controller.onNavigationTap(5),
                    onRefresh: () => controller.refreshAllData(context),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Left Sidebar: Categories
                        Container(
                          width: isDesktop ? 200 : 250,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: GlassPanel(
                            opacity: 0.1,
                            blur: 20,
                            gradient: contentPanelGradient,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: controller.seriesCategories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final category =
                                    controller.seriesCategories[index];
                                final isSelected =
                                    _selectedCategory?.category.categoryId ==
                                    category.category.categoryId;
                                return SidebarItem(
                                  icon: _getCategoryIcon(
                                    category.category.categoryId,
                                  ),
                                  label: category.category.categoryName,
                                  selected: isSelected,
                                  count:
                                      _categoryCounts[category
                                          .category
                                          .categoryId],
                                  onTap: () {
                                    if (!isSelected) {
                                      _onCategorySelected(category);
                                      _scrollController.jumpTo(0);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),

                        // Right Grid: Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    bottom: 12,
                                  ),
                                  child: Text(
                                    _selectedCategory?.category.categoryName ??
                                        '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.1,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double availableWidth =
                                          constraints.maxWidth;
                                      int crossAxisCount = isDesktop
                                          ? 5
                                          : (availableWidth / 180)
                                                .floor()
                                                .clamp(2, 10);

                                      return GridView.builder(
                                        controller: _scrollController,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: crossAxisCount,
                                              childAspectRatio:
                                                  2 /
                                                  3, // 2:3 movie poster ratio
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 20,
                                            ),
                                        itemCount:
                                            _currentItems.length +
                                            (_isMoreLoading ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index < _currentItems.length) {
                                            final item = _currentItems[index];
                                            return PosterCard(
                                              title: item.name,
                                              imageUrl: item.imagePath,
                                              rating: item.seriesStream?.rating,
                                              onTap: () =>
                                                  navigateByContentType(
                                                    context,
                                                    item,
                                                  ),
                                            );
                                          } else {
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFFC12CFF),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  IconData _getCategoryIcon(String categoryId) {
    if (categoryId == IptvRepository.virtualAll) return Icons.grid_view_rounded;
    if (categoryId == IptvRepository.virtualFavorites)
      return Icons.favorite_rounded;
    if (categoryId == IptvRepository.virtualHistory)
      return Icons.history_rounded;
    return Icons.tv_outlined;
  }
}
