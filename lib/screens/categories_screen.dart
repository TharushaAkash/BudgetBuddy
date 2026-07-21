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
          tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(context, provider, CategoryType.expense),
          _buildGrid(context, provider, CategoryType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showCategorySheet(
          context,
          provider,
          type: _tabController.index == 0 ? CategoryType.expense : CategoryType.income,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, FinanceProvider provider, CategoryType type) {
    final list = provider.categories.where((c) => c.type == type).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final c = list[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCategorySheet(context, provider, existing: c, type: type),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: c.color.withOpacity(0.15),
                  child: Icon(c.icon, color: c.color),
                ),
                const SizedBox(height: 8),
                Text(
                  c.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
    int colorValue = existing?.colorValue ?? 0xFF2E7D5A;

    final colorOptions = [0xFF2E7D5A, 0xFF1565C0, 0xFFC62828, 0xFF6A1B9A, 0xFFEF6C00, 0xFF00695C, 0xFF558B2F, 0xFF5E35B1, 0xFFD81B60, 0xFF757575];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(existing == null ? 'New Category' : 'Edit Category', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (existing != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                          onPressed: () async {
                            await provider.deleteCategory(existing.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: kCategoryIcons.entries.map((entry) {
                        final selected = iconKey == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => setState(() => iconKey = entry.key),
                            child: CircleAvatar(
                              backgroundColor: selected ? Color(colorValue) : Colors.grey.withOpacity(0.15),
                              child: Icon(entry.value, color: selected ? Colors.white : Colors.grey.shade700, size: 18),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colorOptions.map((cv) {
                      final selected = colorValue == cv;
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => colorValue = cv),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(cv),
                          child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: const Text('Save Category'),
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
