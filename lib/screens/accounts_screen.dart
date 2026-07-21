import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Net Worth', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  Formatters.currency(provider.totalBalance, provider.currencySymbol),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...provider.accounts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showAccountSheet(context, provider, existing: a),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: a.color.withOpacity(0.15),
                          child: Icon(a.icon, color: a.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(kAccountLabels[a.type] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.currency(provider.accountBalance(a.id), provider.currencySymbol),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAccountSheet(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAccountSheet(BuildContext context, FinanceProvider provider, {AccountModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final balanceController = TextEditingController(text: existing?.openingBalance.toStringAsFixed(0) ?? '0');
    AccountType type = existing?.type ?? AccountType.cash;

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
                      Text(existing == null ? 'New Account' : 'Edit Account', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (existing != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                          onPressed: () async {
                            await provider.deleteAccount(existing.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Account name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: AccountType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(kAccountLabels[t] ?? t.name)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Opening balance', prefixText: '${provider.currencySymbol} ', border: const OutlineInputBorder()),
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
                        final balance = double.tryParse(balanceController.text) ?? 0;
                        if (name.isEmpty) return;
                        if (existing == null) {
                          await provider.addAccount(AccountModel(
                            id: provider.newId(),
                            name: name,
                            type: type,
                            openingBalance: balance,
                            colorValue: 0xFF2E7D5A,
                          ));
                        } else {
                          existing.name = name;
                          existing.type = type;
                          existing.openingBalance = balance;
                          await provider.updateAccount(existing);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Account'),
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
