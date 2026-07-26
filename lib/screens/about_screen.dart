import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/app_theme.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  final String _sourceforgeLink = 'https://sourceforge.net/projects/budgetbuddy';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.cardGradientDark : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'BudgetBuddy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData ? snapshot.data!.version : '1.0.0';
                    return Text(
                      'Finance Tracker • Version $version',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('DEVELOPER INFO', isDark),
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
                  leading: const Icon(Icons.person, color: AppColors.primary),
                  title: const Text('Developer', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tharusha Akash'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: AppColors.primary),
                  title: const Text('GitHub Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('github.com/TharushaAkash'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () async {
                    final uri = Uri.parse('https://github.com/TharushaAkash');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('PUBLICATION', isDark),
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
                const ListTile(
                  leading: Icon(Icons.public, color: AppColors.primary),
                  title: Text('Published on SourceForge', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Download the latest updates and share with friends.'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _sourceforgeLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SourceForge link copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy SourceForge Link'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, bool isDark) => Padding(
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
