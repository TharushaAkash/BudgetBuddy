import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _currencies = ['\$', '€', '£', '¥', '₹', '₨', 'د.إ', 'A\$'];
  bool _smsPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkSmsPermission();
  }

  Future<void> _checkSmsPermission() async {
    final status = await Permission.sms.status;
    setState(() => _smsPermissionGranted = status.isGranted);
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    setState(() => _smsPermissionGranted = status.isGranted);
    if (!status.isGranted && mounted) {
      openAppSettings();
    }
  }

  Future<void> _editName(FinanceProvider provider) async {
    final ctrl = TextEditingController(text: provider.userName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Tharusha'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.updateUserName(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_smsPermissionGranted) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: ListTile(
                leading: const Icon(Icons.sms_failed, color: Colors.redAccent),
                title: const Text('SMS Permission Required', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text('Grant permission to automate bank transactions.', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                trailing: FilledButton.tonal(
                  onPressed: _requestSmsPermission,
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent),
                  child: const Text('Allow'),
                ),
              ),
            ),
          ],
          _sectionTitle('Preferences'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Your Name'),
                  subtitle: Text(provider.userName.isEmpty ? 'Not set' : provider.userName),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editName(provider),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme'),
                  trailing: DropdownButton<ThemeMode>(
                    value: provider.themeMode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (v) {
                      if (v != null) provider.setThemeMode(v);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: _currencies.contains(provider.currencySymbol) ? provider.currencySymbol : _currencies.first,
                    underline: const SizedBox.shrink(),
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) {
                      if (v != null) provider.setCurrencySymbol(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Manage'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Accounts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('About'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Finance Tracker'),
              subtitle: Text('Version 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
      );
}
