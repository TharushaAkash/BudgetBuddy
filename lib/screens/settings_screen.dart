import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import '../providers/auth_provider.dart';
import '../services/backup_service.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Enter Your Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Tharusha'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (!_smsPermissionGranted) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sms_failed_rounded, color: AppColors.expense, size: 20),
                ),
                title: const Text('SMS Permission Required', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Grant permission to auto-detect bank SMS transactions.', style: TextStyle(fontSize: 11, color: AppColors.expense)),
                trailing: FilledButton(
                  onPressed: _requestSmsPermission,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.expense,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Allow'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('SECURITY', isDark),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                  title: const Text('Fingerprint Lock', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Require fingerprint to unlock app', style: TextStyle(fontSize: 12)),
                  value: provider.isBiometricEnabled,
                  onChanged: (bool value) async {
                    if (value) {
                      final statusError = await provider.checkBiometricStatus();
                      if (statusError != null && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                                SizedBox(width: 8),
                                Text('Fingerprint Lock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            content: Text(statusError),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                    }

                    final success = await provider.setBiometricEnabled(value);
                    if (!success && value && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fingerprint authentication cancelled or failed'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  title: const Text('Installment Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Daily notifications for upcoming due dates', style: TextStyle(fontSize: 12)),
                  value: provider.notificationsEnabled,
                  onChanged: (bool value) async {
                    await provider.setNotificationsEnabled(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('CLOUD BACKUP (GOOGLE DRIVE)', isDark),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                if (user == null)
                  ListTile(
                    leading: const Icon(Icons.login_rounded, color: AppColors.primary),
                    title: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Required for cloud backup', style: TextStyle(fontSize: 12)),
                    onTap: () => authProvider.signIn(),
                  )
                else ...[
                  ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    title: Text(user.displayName ?? 'Google Account', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                    trailing: TextButton(
                      onPressed: () => authProvider.signOut(),
                      child: const Text('Sign Out', style: TextStyle(color: AppColors.expense)),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                    title: const Text('Backup Now', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: FutureBuilder<String?>(
                      future: BackupService.getLastBackupTime(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final date = DateTime.parse(snapshot.data!);
                          return Text('Last: ${date.toString().split('.')[0]}', style: const TextStyle(fontSize: 12));
                        }
                        return const Text('No recent backup', style: TextStyle(fontSize: 12));
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final client = await authProvider.getAuthenticatedClient();
                      if (client != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting backup...')),
                          );
                        }
                        final success = await BackupService.performBackup(client);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Backup Successful!' : 'Backup Failed.'),
                              backgroundColor: success ? AppColors.income : AppColors.expense,
                            ),
                          );
                          setState(() {});
                        }
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_download_outlined, color: AppColors.income),
                    title: const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Download backup from Google Drive', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final client = await authProvider.getAuthenticatedClient();
                      if (client != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting restore...')),
                          );
                        }
                        final success = await BackupService.restoreBackup(client, () {
                          provider.reload();
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Restore Successful!' : 'Restore Failed or No backup found.'),
                              backgroundColor: success ? AppColors.income : AppColors.expense,
                            ),
                          );
                          setState(() {});
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('PREFERENCES', isDark),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  title: const Text('Your Name', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(provider.userName.isEmpty ? 'Not set' : provider.userName),
                  trailing: const Icon(Icons.edit_rounded, size: 18),
                  onTap: () => _editName(provider),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  leading: const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                  title: const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 20),
          _sectionTitle('MANAGE DATA', isDark),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                  title: const Text('Accounts & Wallets', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                  title: const Text('Transaction Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('ABOUT APP', isDark),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: const ListTile(
              leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
              title: Text('BudgetBuddy Finance Tracker', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Version 1.0.0 • Modern Edition'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
}

