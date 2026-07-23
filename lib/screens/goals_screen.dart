import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/goal_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../services/ai_service.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final goals = provider.goals;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
      ),
      body: goals.isEmpty
          ? Center(
              child: Text(
                'No goals yet.\nTap + to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _GoalCard(goal: goal);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void _showGoalDialog(BuildContext context, [GoalModel? goal]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalFormSheet(goal: goal),
    );
  }
}

class _GoalCard extends StatefulWidget {
  final GoalModel goal;
  const _GoalCard({required this.goal});

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  String? _suggestion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestion();
  }

  Future<void> _fetchSuggestion() async {
    if (widget.goal.isCompleted) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<FinanceProvider>();
      final summary = provider.getFinancialSummary();
      final text = await AiService.getGoalSuggestion(widget.goal, summary);
      if (mounted) setState(() => _suggestion = text);
    } catch (e) {
      // Ignore AI errors gracefully
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goal = widget.goal;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: () => GoalsScreen._showGoalDialog(context, goal),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: goal.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(goal.icon, color: goal.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${Formatters.date(goal.targetDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    onPressed: () => _showAddFundsDialog(context, goal),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.currency(goal.savedAmount, provider.currencySymbol),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: goal.isCompleted ? AppColors.income : null,
                    ),
                  ),
                  Text(
                    Formatters.currency(goal.targetAmount, provider.currencySymbol),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(goal.isCompleted ? AppColors.income : goal.color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(goal.progress * 100).toStringAsFixed(1)}% Completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
              if (!goal.isCompleted && (_isLoading || _suggestion != null)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoading
                            ? const Text(
                                'AI is thinking...',
                                style: TextStyle(fontSize: 12, color: Colors.amber, fontStyle: FontStyle.italic),
                              )
                            : Text(
                                _suggestion!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, GoalModel goal) {
    final provider = context.read<FinanceProvider>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Funds'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: provider.currencySymbol,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                final updated = GoalModel(
                  id: goal.id,
                  name: goal.name,
                  targetAmount: goal.targetAmount,
                  savedAmount: goal.savedAmount + amount,
                  targetDate: goal.targetDate,
                  colorValue: goal.colorValue,
                  iconCodePoint: goal.iconCodePoint,
                );
                provider.updateGoal(updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  final GoalModel? goal;
  const _GoalFormSheet({this.goal});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 30));
  Color _color = AppColors.primary;
  
  final _colors = const [
    AppColors.primary, AppColors.income, AppColors.expense,
    Colors.purple, Colors.orange, Colors.teal, Colors.blue, Colors.pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _amountController.text = widget.goal!.targetAmount.toString();
      _date = widget.goal!.targetDate;
      _color = widget.goal!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.goal == null ? 'New Goal' : 'Edit Goal',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (widget.goal != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                      onPressed: () {
                        provider.deleteGoal(widget.goal!.id);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Goal Name (e.g. Dream Car)'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: provider.currencySymbol,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target Date'),
                subtitle: Text(Formatters.date(_date)),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((c) {
                  final selected = c.toARGB32() == _color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) return;
                    final amt = double.tryParse(_amountController.text) ?? 0;
                    if (amt <= 0) return;

                    final goal = GoalModel(
                      id: widget.goal?.id ?? const Uuid().v4(),
                      name: _nameController.text.trim(),
                      targetAmount: amt,
                      savedAmount: widget.goal?.savedAmount ?? 0,
                      targetDate: _date,
                      colorValue: _color.toARGB32(),
                      iconCodePoint: Icons.flag_rounded.codePoint,
                    );

                    if (widget.goal == null) {
                      provider.addGoal(goal);
                    } else {
                      provider.updateGoal(goal);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
