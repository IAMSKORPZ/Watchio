import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/xtream_code_home_controller.dart';
import '../../models/category_view_model.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../shared/widgets/sidebar_item.dart';
import '../../shared/widgets/poster_card.dart';
import '../../utils/navigate_by_content_type.dart';

class XtreamMoviesScreen extends StatefulWidget {
  const XtreamMoviesScreen({super.key});

  @override
  State<XtreamMoviesScreen> createState() => _XtreamMoviesScreenState();
}

class _XtreamMoviesScreenState extends State<XtreamMoviesScreen> {
  CategoryViewModel? _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<XtreamCodeHomeController>(context, listen: false);
      if (controller.movieCategories.isNotEmpty) {
        setState(() {
          _selectedCategory = controller.movieCategories.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<XtreamCodeHomeController>(
      builder: (context, controller, child) {
        if (controller.movieCategories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          children: [
            // Left Sidebar: Categories
            Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              child: GlassPanel(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: controller.movieCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final category = controller.movieCategories[index];
                    final isSelected = _selectedCategory?.category.categoryId == category.category.categoryId;
                    return SidebarItem(
                      icon: Icons.movie_outlined,
                      label: category.category.categoryName,
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      },
                    );
                  },
                ),
              ),
            ),

            // Right Grid: Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16),
                      child: Text(
                        _selectedCategory?.category.categoryName ?? '',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _selectedCategory?.contentItems.length ?? 0,
                        itemBuilder: (context, index) {
                          final item = _selectedCategory!.contentItems[index];
                          return PosterCard(
                            title: item.name,
                            imageUrl: item.imagePath,
                            rating: item.vodStream?.rating,
                            onTap: () => navigateByContentType(context, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
