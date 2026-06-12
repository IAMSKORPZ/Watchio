import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/xtream_code_home_controller.dart';
import '../../models/category_view_model.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../shared/widgets/sidebar_item.dart';
import '../../utils/navigate_by_content_type.dart';

class XtreamLiveScreen extends StatefulWidget {
  const XtreamLiveScreen({super.key});

  @override
  State<XtreamLiveScreen> createState() => _XtreamLiveScreenState();
}

class _XtreamLiveScreenState extends State<XtreamLiveScreen> {
  CategoryViewModel? _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<XtreamCodeHomeController>(context, listen: false);
      if (controller.liveCategories != null && controller.liveCategories!.isNotEmpty) {
        setState(() {
          _selectedCategory = controller.liveCategories!.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<XtreamCodeHomeController>(
      builder: (context, controller, child) {
        if (controller.liveCategories == null || controller.liveCategories!.isEmpty) {
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
                  itemCount: controller.liveCategories!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final category = controller.liveCategories![index];
                    final isSelected = _selectedCategory?.category.categoryId == category.category.categoryId;
                    return SidebarItem(
                      icon: Icons.live_tv_rounded,
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

            // Right: Channel List
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
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(right: 8),
                        itemCount: _selectedCategory?.contentItems.length ?? 0,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _selectedCategory!.contentItems[index];
                          return GlassPanel(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: InkWell(
                              onTap: () => navigateByContentType(context, item),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  // Channel Icon
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: item.imagePath.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              item.imagePath,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) => const Icon(Icons.live_tv, color: Colors.white24),
                                            ),
                                          )
                                        : const Icon(Icons.live_tv, color: Colors.white24),
                                  ),
                                  const SizedBox(width: 16),
                                  // Channel Name & Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'EPG info not available',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.play_circle_outline, color: Colors.blue),
                                ],
                              ),
                            ),
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
