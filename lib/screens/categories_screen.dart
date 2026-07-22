import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [Tab(text: 'Expense Categories'), Tab(text: 'Income Categories')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(context, provider, CategoryType.expense),
          _buildGrid(context, provider, CategoryType.income),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton(
          heroTag: 'cat_fab',
          onPressed: () => _showCategorySheet(
            context,
            provider,
            type: _tabController.index == 0 ? CategoryType.expense : CategoryType.income,
          ),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, FinanceProvider provider, CategoryType type) {
    final list = provider.categories.where((c) => c.type == type).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final c = list[i];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCategorySheet(context, provider, existing: c, type: type),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.color.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(c.icon, color: c.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  c.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategorySheet(BuildContext context, FinanceProvider provider, {CategoryModel? existing, required CategoryType type}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String iconKey = existing?.iconKey ?? kCategoryIcons.keys.first;
    int colorValue = existing?.colorValue ?? 0xFF0F766E;

    final colorOptions = [
      0xFF0F766E,
      0xFF10B981,
      0xFF3B82F6,
      0xFF6366F1,
      0xFF8B5CF6,
      0xFFEC4899,
      0xFFF43F5E,
      0xFFF59E0B,
      0xFF0284C7,
      0xFF64748B,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'New Category' : 'Edit Category',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (existing != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                          onPressed: () async {
                            await provider.deleteCategory(existing.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Dining out'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: kCategoryIcons.entries.map((entry) {
                        final selected = iconKey == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => setState(() => iconKey = entry.key),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: selected ? Color(colorValue) : Colors.grey.withValues(alpha: 0.15),
                              child: Icon(entry.value, color: selected ? Colors.white : Colors.grey.shade700, size: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colorOptions.map((cv) {
                      final selected = colorValue == cv;
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => colorValue = cv),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(cv),
                          child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        if (existing == null) {
                          await provider.addCategory(CategoryModel(
                            id: provider.newId(),
                            name: name,
                            iconKey: iconKey,
                            colorValue: colorValue,
                            type: type,
                          ));
                        } else {
                          existing.name = name;
                          existing.iconKey = iconKey;
                          existing.colorValue = colorValue;
                          await provider.updateCategory(existing);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

