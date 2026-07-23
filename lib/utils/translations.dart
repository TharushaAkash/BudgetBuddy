import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      // Dashboard
      'total_net_worth': 'TOTAL NET WORTH',
      'income_this_month': 'Income this month',
      'expense_this_month': 'Expense this month',
      'vs_last_month': 'vs last month',
      'expense': 'Expense',
      'income': 'Income',
      'petty_cash': 'Petty Cash',
      'loans': 'Loans',
      'recent_transactions': 'Recent Transactions',
      'view_all': 'View All',
      'no_transactions_yet': 'No transactions yet',

      // Drawer
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'financial_goals': 'Financial Goals',
      'loan_installments': 'Loan & Installments',
      'manage_accounts': 'Manage Accounts',
      'settings': 'Settings',

      // Settings
      'ai_assistant': 'AI ASSISTANT',
      'gemini_api_key': 'OpenRouter API Key',
      'gemini_api_key_sub': 'Required for AI Financial Advisor',
      'preferences': 'PREFERENCES',
      'language': 'Language / භාෂාව',
      'language_sub': 'English / සිංහල',
      'dark_mode': 'Dark Mode',
      'currency': 'Currency',
      'data_management': 'DATA MANAGEMENT',
      'backup_data': 'Backup Data',
      'backup_data_sub': 'Save to Google Drive',
      'restore_data': 'Restore Data',
      'restore_data_sub': 'Download backup from Google Drive',
      'categories': 'CATEGORIES',
      'transaction_categories': 'Transaction Categories',
      'about_app': 'ABOUT APP',
      'save': 'Save',
      'cancel': 'Cancel',

      // Common
      'amount': 'AMOUNT',
      'note_optional': 'Note (Optional)',
      'note': 'Note',
      'date': 'Date',
      'repeat': 'Repeat',
      'account': 'Account',
      'category': 'Category',
      'add': 'Add',
      'edit': 'Edit',
      'delete': 'Delete',
      
      // Accounts
      'cash': 'Cash',
      'bank': 'Bank',
      
      // Goals
      'target': 'Target:',
      'completed': 'Completed',
      'add_funds': 'Add Funds',
      'no_goals_yet': 'No goals yet.\nTap + to create one!',
      
      // Add Transaction
      'add_transaction': 'Add Transaction',
      'edit_transaction': 'Edit Transaction',
      'transfer_between_accounts': 'Transfer between accounts',
      'from_account': 'From Account',
      'to_account': 'To Account',
      'title': 'Title',
    },
    'si': {
      // Dashboard
      'total_net_worth': 'මුළු වත්කම',
      'income_this_month': 'මේ මාසයේ ආදායම',
      'expense_this_month': 'මේ මාසයේ වියදම',
      'vs_last_month': 'පසුගිය මාසයට සාපේක්ෂව',
      'expense': 'වියදම්',
      'income': 'ආදායම්',
      'petty_cash': 'සුළු මුදල් (Petty Cash)',
      'loans': 'ණය (Loans)',
      'recent_transactions': 'මෑතකාලීන ගනුදෙනු',
      'view_all': 'සියල්ල බලන්න',
      'no_transactions_yet': 'තවම ගනුදෙනු කිසිවක් නැත',

      // Drawer
      'dashboard': 'මුල් පිටුව',
      'transactions': 'ගනුදෙනු',
      'financial_goals': 'මූල්‍ය ඉලක්ක',
      'loan_installments': 'ණය සහ වාරික',
      'manage_accounts': 'ගිණුම් කළමනාකරණය',
      'settings': 'සැකසුම්',

      // Settings
      'ai_assistant': 'AI සහායකයා',
      'gemini_api_key': 'OpenRouter API Key',
      'gemini_api_key_sub': 'AI උපදේශක සඳහා අවශ්‍ය වේ',
      'preferences': 'මනාපයන් (PREFERENCES)',
      'language': 'භාෂාව / Language',
      'language_sub': 'සිංහල / English',
      'dark_mode': 'අඳුරු තේමාව (Dark Mode)',
      'currency': 'මුදල් ඒකකය (Currency)',
      'data_management': 'දත්ත කළමනාකරණය',
      'backup_data': 'දත්ත සුරකින්න (Backup)',
      'backup_data_sub': 'Google Drive වෙත සුරකින්න',
      'restore_data': 'දත්ත නැවත ලබාගන්න (Restore)',
      'restore_data_sub': 'Google Drive වෙතින් ලබාගන්න',
      'categories': 'කාණ්ඩ (CATEGORIES)',
      'transaction_categories': 'ගනුදෙනු කාණ්ඩ',
      'about_app': 'යෙදුම ගැන (ABOUT APP)',
      'save': 'සුරකින්න',
      'cancel': 'අවලංගු කරන්න',

      // Common
      'amount': 'මුදල (AMOUNT)',
      'note_optional': 'සටහන (විකල්ප)',
      'note': 'සටහන (විකල්ප)',
      'date': 'දිනය',
      'repeat': 'පුනරාවර්තනය (Repeat)',
      'account': 'ගිණුම',
      'category': 'කාණ්ඩය',
      'add': 'එකතු කරන්න',
      'edit': 'සංස්කරණය',
      'delete': 'මකන්න',
      'search': 'සොයන්න...',

      // Accounts
      'cash': 'අතේ ඇති මුදල් (Cash)',
      'bank': 'බැංකු ගිණුම්',

      // Goals
      'target': 'ඉලක්කය:',
      'completed': 'සම්පූර්ණයි',
      'add_funds': 'මුදල් එකතු කරන්න',
      'no_goals_yet': 'තවම ඉලක්ක කිසිවක් නැත.\nඑකක් සෑදීමට + ඔබන්න!',

      // Add Transaction
      'add_transaction': 'ගනුදෙනුවක් එකතු කරන්න',
      'edit_transaction': 'ගනුදෙනුව වෙනස් කරන්න',
      'transfer_between_accounts': 'ගිණුම් අතර මුදල් මාරු කරන්න',
      'from_account': 'මුදල් යවන ගිණුම',
      'to_account': 'මුදල් ලබන ගිණුම',
      'title': 'මාතෘකාව',
    }
  };

  static String get(String key, String langCode) {
    return translations[langCode]?[key] ?? translations['en']?[key] ?? key;
  }
}

extension StringTranslate on String {
  String tr(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: true).languageCode;
    return AppTranslations.get(this, lang);
  }
}
