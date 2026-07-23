import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:readsms/readsms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as inbox;

import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/installment_model.dart';
import '../models/goal_model.dart';
import '../services/notification_service.dart';

class FinanceProvider extends ChangeNotifier {
  static const _kAccountsKey = 'ft_accounts';
  static const _kCategoriesKey = 'ft_categories';
  static const _kTransactionsKey = 'ft_transactions';
  static const _kBudgetsKey = 'ft_budgets';
  static const _kThemeKey = 'ft_theme_mode';
  static const _kCurrencyKey = 'ft_currency';
  static const _kInstallmentsKey = 'ft_installments';
  static const _kGoalsKey = 'ft_goals';
  static const _kUserNameKey = 'ft_user_name';
  static const _kBiometricKey = 'ft_biometric_enabled';
  static const _kNotificationsKey = 'ft_notifications_enabled';

  final _uuid = const Uuid();
  final _smsPlugin = Readsms();
  final _localAuth = LocalAuthentication();

  List<AccountModel> accounts = [];
  List<CategoryModel> categories = [];
  List<TransactionModel> transactions = [];
  List<BudgetModel> budgets = [];
  List<InstallmentModel> installments = [];
  List<GoalModel> goals = [];

  ThemeMode themeMode = ThemeMode.system;
  String currencySymbol = '\$';
  String userName = '';
  bool isBiometricEnabled = false;
  bool notificationsEnabled = false;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  FinanceProvider() {
    _load();
  }

  // ---------------- Persistence ----------------

  Future<void> reload() async {
    await _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final accJson = prefs.getString(_kAccountsKey);
    final catJson = prefs.getString(_kCategoriesKey);
    final txJson = prefs.getString(_kTransactionsKey);
    final budJson = prefs.getString(_kBudgetsKey);
    final themeIndex = prefs.getInt(_kThemeKey);
    final currency = prefs.getString(_kCurrencyKey);
    
    final instJson = prefs.getString(_kInstallmentsKey);
    final goalsJson = prefs.getString(_kGoalsKey);

    accounts = accJson != null
        ? (jsonDecode(accJson) as List).map((e) => AccountModel.fromJson(e)).toList()
        : AccountModel.defaults();

    categories = catJson != null
        ? (jsonDecode(catJson) as List).map((e) => CategoryModel.fromJson(e)).toList()
        : CategoryModel.defaults();

    transactions = txJson != null
        ? (jsonDecode(txJson) as List).map((e) => TransactionModel.fromJson(e)).toList()
        : [];

    budgets = budJson != null ? (jsonDecode(budJson) as List).map((e) => BudgetModel.fromJson(e)).toList() : [];
    
    installments = instJson != null
        ? (jsonDecode(instJson) as List).map((e) => InstallmentModel.fromJson(e)).toList()
        : [];

    goals = goalsJson != null
        ? (jsonDecode(goalsJson) as List).map((e) => GoalModel.fromJson(e)).toList()
        : [];

    if (themeIndex != null) themeMode = ThemeMode.values[themeIndex];
    if (currency != null) currencySymbol = currency;
    userName = prefs.getString(_kUserNameKey) ?? '';
    isBiometricEnabled = prefs.getBool(_kBiometricKey) ?? false;
    notificationsEnabled = prefs.getBool(_kNotificationsKey) ?? false;

    if (!accounts.any((a) => a.type == AccountType.petty_cash)) {
      accounts.add(AccountModel(id: _uuid.v4(), name: 'Petty Cash', type: AccountType.petty_cash, openingBalance: 0, colorValue: 0xFFFF9800));
    }

    _loaded = true;
    notifyListeners();

    // Persist defaults on first run.
    if (accJson == null) await _saveAccounts();
    if (catJson == null) await _saveCategories();
    if (txJson == null) await _saveTransactions();
    if (budJson == null) await _saveBudgets();
    if (instJson == null) await _saveInstallments();
    if (goalsJson == null) await _saveGoals();

    initSmsListener();
    syncMissedSms();
    _checkPettyCashReset();
    rescheduleAllInstallmentNotifications();
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccountsKey, jsonEncode(accounts.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCategoriesKey, jsonEncode(categories.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTransactionsKey, jsonEncode(transactions.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBudgetsKey, jsonEncode(budgets.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveInstallments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInstallmentsKey, jsonEncode(installments.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGoalsKey, jsonEncode(goals.map((e) => e.toJson()).toList()));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeKey, mode.index);
  }

  Future<void> setCurrencySymbol(String symbol) async {
    currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, symbol);
  }

  Future<void> updateUserName(String name) async {
    userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserNameKey, name);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsKey, enabled);
    
    if (enabled) {
      await NotificationService().requestPermission();
    }
    
    rescheduleAllInstallmentNotifications();
    notifyListeners();
  }

  void rescheduleAllInstallmentNotifications() async {
    final service = NotificationService();
    await service.cancelAllNotifications();
    
    if (!notificationsEnabled) return;

    for (final inst in installments) {
      if (!inst.isCompleted) {
        final date = inst.nextPaymentDate;
        if (date != null) {
          await service.scheduleInstallmentNotifications(inst.id, inst.item, date);
        }
      }
    }
  }

  // ---------------- Biometric Authentication ----------------

  Future<String?> checkBiometricStatus() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        return 'Biometric authentication is not supported on this device.';
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return 'No fingerprint or biometric credentials enrolled on this device. Please set up a fingerprint in device settings.';
      }

      return null; // Null means ready and enrolled!
    } catch (e) {
      return 'Biometric error: ${e.toString()}';
    }
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final statusError = await checkBiometricStatus();
      if (statusError != null) {
        // Device biometrics not enrolled or supported
        return false;
      }

      final success = await authenticateBiometric(
        reason: 'Scan your fingerprint to enable biometric lock',
      );

      if (success) {
        isBiometricEnabled = true;
        await prefs.setBool(_kBiometricKey, true);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } else {
      isBiometricEnabled = false;
      await prefs.setBool(_kBiometricKey, false);
      notifyListeners();
      return true;
    }
  }

  Future<bool> authenticateBiometric({String reason = 'Authenticate to access BudgetBuddy'}) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows device PIN/pattern fallback if fingerprint hardware is unavailable
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------- SMS Automation ----------------

  void initSmsListener() async {
    if (await Permission.sms.request().isGranted) {
      _smsPlugin.read();
      _smsPlugin.smsStream.listen((SMS sms) {
        _processSms(sms.sender, sms.body);
      });
    }
  }

  Future<void> syncMissedSms() async {
    if (await Permission.sms.isGranted) {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('ft_last_sms_sync');
      
      // Default to 2 days ago if first time, so we don't scan thousands of old messages
      DateTime lastSync = lastSyncStr != null 
          ? DateTime.parse(lastSyncStr) 
          : DateTime.now().subtract(const Duration(days: 2));

      final smsQuery = inbox.SmsQuery();
      final messages = await smsQuery.querySms(
        kinds: [inbox.SmsQueryKind.inbox],
      );

      for (final msg in messages) {
        if (msg.date != null && msg.date!.isAfter(lastSync)) {
          if (msg.address != null && msg.body != null) {
            _processSms(msg.address!, msg.body!, msg.date!);
          }
        }
      }

      await prefs.setString('ft_last_sms_sync', DateTime.now().toIso8601String());
    }
  }

  Future<void> _checkPettyCashReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('ft_petty_cash_reset');
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    if (lastResetStr != todayStr) {
      if (lastResetStr == null) {
        await prefs.setString('ft_petty_cash_reset', todayStr);
        return;
      }

      try {
        final pettyAccount = accounts.firstWhere((a) => a.type == AccountType.petty_cash);
        final cashAccount = accounts.firstWhere((a) => a.type == AccountType.cash);
        
        final pettyBalance = accountBalance(pettyAccount.id);
        
        if (pettyBalance > 0) {
          final t = TransactionModel(
            id: _uuid.v4(),
            title: 'Petty Cash Reset Transfer',
            amount: pettyBalance,
            type: CategoryType.expense,
            categoryId: categories.first.id,
            accountId: pettyAccount.id,
            toAccountId: cashAccount.id,
            date: DateTime(now.year, now.month, now.day, 0, 0, 1),
            note: 'Auto reset remaining petty cash to main cash account',
          );
          
          transactions.add(t);
          await _saveTransactions();
          notifyListeners();
        }
      } catch (_) {}
      
      await prefs.setString('ft_petty_cash_reset', todayStr);
    }
  }

  void _processSms(String sender, String body, [DateTime? date]) {
    final bodyLower = body.toLowerCase();
    
    bool isWithdrawal = bodyLower.contains('withdrawel') || bodyLower.contains('withdrawal') || bodyLower.contains('withdrawn');
    bool isDeposit = bodyLower.contains('deposit');
    
    bool isCredit = bodyLower.contains('credited') || bodyLower.contains('received');
    bool isDebit = bodyLower.contains('debited') || bodyLower.contains('paid');

    if (isCredit || isDebit || isWithdrawal || isDeposit) {
      final amountRegex = RegExp(r'(?:lkr|rs\.?)\s*([\d,]+\.?\d*)', caseSensitive: false);
      final match = amountRegex.firstMatch(bodyLower);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
        final amount = double.tryParse(amountStr) ?? 0;

        if (amount > 0 && accounts.isNotEmpty) {
          TransactionModel t;
          
          if (isWithdrawal || isDeposit) {
            final bankAccount = accounts.firstWhere((a) => a.type == AccountType.bank, orElse: () => accounts.first);
            final cashAccount = accounts.firstWhere((a) => a.type == AccountType.cash, orElse: () => accounts.first);
            
            final title = isWithdrawal ? 'ATM Withdrawal (Auto)' : 'Cash Deposit (Auto)';
            final fromAccId = isWithdrawal ? bankAccount.id : cashAccount.id;
            final toAccId = isWithdrawal ? cashAccount.id : bankAccount.id;
            
            t = TransactionModel(
              id: _uuid.v4(),
              title: title,
              amount: amount,
              type: CategoryType.expense,
              categoryId: categories.isNotEmpty ? categories.first.id : 'c1',
              accountId: fromAccId,
              toAccountId: toAccId,
              date: date ?? DateTime.now(),
              note: 'Auto-added Transfer from SMS: $sender',
            );
          } else {
            final type = isCredit ? CategoryType.income : CategoryType.expense;
            final title = isCredit ? 'Bank Credit (Auto)' : 'Bank Debit (Auto)';
            
            final defaultCat = categories.firstWhere(
              (c) => c.type == type, 
              orElse: () => categories.first
            );

            t = TransactionModel(
              id: _uuid.v4(),
              title: title,
              amount: amount,
              type: type,
              categoryId: defaultCat.id,
              accountId: accounts.firstWhere((a) => a.type == AccountType.bank, orElse: () => accounts.first).id,
              date: date ?? DateTime.now(),
              note: 'Auto-added from SMS: $sender',
            );
          }
          
          addTransaction(t);
        }
      }
    }
  }



  // ---------------- Transactions CRUD ----------------

  Future<void> addTransaction(TransactionModel t) async {
    transactions.add(t);
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> updateTransaction(TransactionModel t) async {
    final idx = transactions.indexWhere((e) => e.id == t.id);
    if (idx != -1) {
      transactions[idx] = t;
      notifyListeners();
      await _saveTransactions();
    }
  }

  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveTransactions();
  }

  String newId() => _uuid.v4();

  // ---------------- Accounts CRUD ----------------

  Future<void> addAccount(AccountModel a) async {
    accounts.add(a);
    notifyListeners();
    await _saveAccounts();
  }

  Future<void> updateAccount(AccountModel a) async {
    final idx = accounts.indexWhere((e) => e.id == a.id);
    if (idx != -1) {
      accounts[idx] = a;
      notifyListeners();
      await _saveAccounts();
    }
  }

  Future<void> deleteAccount(String id) async {
    accounts.removeWhere((e) => e.id == id);
    transactions.removeWhere((e) => e.accountId == id || e.toAccountId == id);
    notifyListeners();
    await _saveAccounts();
    await _saveTransactions();
  }

  // ---------------- Categories CRUD ----------------

  Future<void> addCategory(CategoryModel c) async {
    categories.add(c);
    notifyListeners();
    await _saveCategories();
  }

  Future<void> updateCategory(CategoryModel c) async {
    final idx = categories.indexWhere((e) => e.id == c.id);
    if (idx != -1) {
      categories[idx] = c;
      notifyListeners();
      await _saveCategories();
    }
  }

  Future<void> deleteCategory(String id) async {
    categories.removeWhere((e) => e.id == id);
    transactions.removeWhere((e) => e.categoryId == id);
    budgets.removeWhere((e) => e.categoryId == id);
    notifyListeners();
    await _saveCategories();
    await _saveTransactions();
    await _saveBudgets();
  }

  // ---------------- Budgets CRUD ----------------

  Future<void> addBudget(BudgetModel b) async {
    budgets.add(b);
    notifyListeners();
    await _saveBudgets();
  }

  Future<void> updateBudget(BudgetModel b) async {
    final idx = budgets.indexWhere((e) => e.id == b.id);
    if (idx != -1) {
      budgets[idx] = b;
      notifyListeners();
      await _saveBudgets();
    }
  }

  Future<void> deleteBudget(String id) async {
    budgets.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveBudgets();
  }

  // ---------------- Installments CRUD ----------------

  Future<void> addInstallment(InstallmentModel inst) async {
    installments.add(inst);
    notifyListeners();
    await _saveInstallments();
    rescheduleAllInstallmentNotifications();
  }

  Future<void> updateInstallment(InstallmentModel inst) async {
    final idx = installments.indexWhere((e) => e.id == inst.id);
    if (idx != -1) {
      installments[idx] = inst;
      notifyListeners();
      await _saveInstallments();
      rescheduleAllInstallmentNotifications();
    }
  }

  Future<void> deleteInstallment(String id) async {
    installments.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveInstallments();
    rescheduleAllInstallmentNotifications();
  }

  double get totalRemainingInstallments {
    return installments.where((i) => !i.isCompleted).fold(0.0, (sum, item) => sum + item.remainingAmount);
  }

  DateTime? get closestNextPaymentDate {
    DateTime? closest;
    for (final inst in installments) {
      if (!inst.isCompleted) {
        final d = inst.nextPaymentDate;
        if (d != null) {
          if (closest == null || d.isBefore(closest)) {
            closest = d;
          }
        }
      }
    }
    return closest;
  }

  // ---------------- Derived data / computations ----------------

  CategoryModel? categoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  AccountModel? accountById(String id) {
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Current balance of a single account = opening balance + all
  /// income/expense/transfers touching this account.
  double accountBalance(String accountId) {
    final acc = accountById(accountId);
    double balance = acc?.openingBalance ?? 0;
    for (final t in transactions) {
      if (t.isTransfer) {
        if (t.accountId == accountId) balance -= t.amount;
        if (t.toAccountId == accountId) balance += t.amount;
      } else if (t.accountId == accountId) {
        balance += t.type == CategoryType.income ? t.amount : -t.amount;
      }
    }
    return balance;
  }

  double get totalBalance => accounts.fold(0.0, (sum, a) => sum + accountBalance(a.id));

  double getPettyCashBalanceAt(DateTime? date) {
    try {
      final pettyAccount = accounts.firstWhere((a) => a.type == AccountType.petty_cash);
      double balance = pettyAccount.openingBalance;
      final endOfDay = date != null ? DateTime(date.year, date.month, date.day, 23, 59, 59) : DateTime.now();

      for (final t in transactions) {
        if (t.date.isAfter(endOfDay)) continue;
        if (t.isTransfer) {
          if (t.accountId == pettyAccount.id) balance -= t.amount;
          if (t.toAccountId == pettyAccount.id) balance += t.amount;
        } else if (t.accountId == pettyAccount.id) {
          balance += t.type == CategoryType.income ? t.amount : -t.amount;
        }
      }
      return balance;
    } catch (_) {
      return 0;
    }
  }

  List<TransactionModel> transactionsInRange(DateTime start, DateTime end) {
    return transactions.where((t) => !t.date.isBefore(start) && t.date.isBefore(end)).toList();
  }

  DateTime get _now => DateTime.now();

  DateTime get monthStart => DateTime(_now.year, _now.month, 1);
  DateTime get monthEnd => DateTime(_now.year, _now.month + 1, 1);

  double totalIncomeInRange(DateTime start, DateTime end) => transactionsInRange(start, end)
      .where((t) => !t.isTransfer && t.type == CategoryType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double totalExpenseInRange(DateTime start, DateTime end) => transactionsInRange(start, end)
      .where((t) => !t.isTransfer && t.type == CategoryType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get monthlyIncome => totalIncomeInRange(monthStart, monthEnd);
  double get monthlyExpense => totalExpenseInRange(monthStart, monthEnd);

  DateTime get lastMonthStart => DateTime(_now.year, _now.month - 1, 1);
  DateTime get lastMonthEnd => DateTime(_now.year, _now.month, 1);

  double get lastMonthIncome => totalIncomeInRange(lastMonthStart, lastMonthEnd);
  double get lastMonthExpense => totalExpenseInRange(lastMonthStart, lastMonthEnd);

  /// Amount spent per category within the current budget period.
  double spentForBudget(BudgetModel b) {
    late DateTime start;
    final now = _now;
    switch (b.period) {
      case BudgetPeriod.weekly:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case BudgetPeriod.monthly:
        start = DateTime(now.year, now.month, 1);
        break;
      case BudgetPeriod.yearly:
        start = DateTime(now.year, 1, 1);
        break;
    }
    return transactions
        .where((t) => !t.isTransfer && t.type == CategoryType.expense && t.categoryId == b.categoryId && !t.date.isBefore(start))
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Map of categoryId -> total spent, for expense breakdown charts.
  Map<String, double> expenseByCategory(DateTime start, DateTime end) {
    final map = <String, double>{};
    for (final t in transactionsInRange(start, end)) {
      if (t.isTransfer || t.type != CategoryType.expense) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  /// Daily net totals for the last [days] days, oldest first.
  List<MapEntry<DateTime, double>> dailyTrend(int days) {
    final now = _now;
    final result = <MapEntry<DateTime, double>>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final income = totalIncomeInRange(day, next);
      final expense = totalExpenseInRange(day, next);
      result.add(MapEntry(day, income - expense));
    }
    return result;
  }

  /// Last [months] months of income vs expense totals, oldest first.
  List<Map<String, dynamic>> monthlyTrend(int months) {
    final now = _now;
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);
      result.add({
        'month': monthDate,
        'income': totalIncomeInRange(monthDate, nextMonth),
        'expense': totalExpenseInRange(monthDate, nextMonth),
      });
    }
    return result;
  }

  List<TransactionModel> get recentTransactions {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  List<TransactionModel> searchTransactions({
    String query = '',
    String? categoryId,
    String? accountId,
    CategoryType? type,
    DateTime? start,
    DateTime? end,
  }) {
    return transactions.where((t) {
      final matchesQuery = query.isEmpty ||
          t.title.toLowerCase().contains(query.toLowerCase()) ||
          t.note.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = categoryId == null || t.categoryId == categoryId;
      final matchesAccount = accountId == null || t.accountId == accountId || t.toAccountId == accountId;
      final matchesType = type == null || t.type == type;
      final matchesStart = start == null || !t.date.isBefore(start);
      final matchesEnd = end == null || t.date.isBefore(end);
      return matchesQuery && matchesCategory && matchesAccount && matchesType && matchesStart && matchesEnd;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ---------------- Goals Management ----------------

  Future<void> addGoal(GoalModel goal) async {
    goals.add(goal);
    notifyListeners();
    await _saveGoals();
  }

  Future<void> updateGoal(GoalModel goal) async {
    final idx = goals.indexWhere((e) => e.id == goal.id);
    if (idx != -1) {
      goals[idx] = goal;
      notifyListeners();
      await _saveGoals();
    }
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveGoals();
  }

  // ---------------- AI Financial Summary ----------------
  String getFinancialSummary() {
    final now = DateTime.now();
    final currentMonthIncome = totalIncomeInRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
    final currentMonthExpense = totalExpenseInRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
    final pettyCash = getPettyCashBalanceAt(now);
    
    final goalsStr = goals.isEmpty ? 'No active goals.' : goals.map((g) => '- ${g.name}: Target ${g.targetAmount}, Saved ${g.savedAmount}, Deadline ${g.targetDate.toString().split(" ")[0]}').join('\n');
    final installmentsStr = installments.isEmpty ? 'No active loans.' : installments.map((i) => '- ${i.shop} ${i.item}: Total ${i.totalAmount}, Paid ${i.paidAmount}, Monthly Payment ${i.monthlyAmount}').join('\n');
    final accountsStr = accounts.isEmpty ? 'No accounts.' : accounts.map((a) => '- ${a.name} (${a.type.name}): Balance ${accountBalance(a.id)}').join('\n');

    return '''
Current Financial Status (As of ${now.toString().split(" ")[0]}):
- Monthly Income (This Month): $currentMonthIncome
- Monthly Expense (This Month): $currentMonthExpense
- Petty Cash Balance: $pettyCash

Accounts:
$accountsStr

Active Goals:
$goalsStr

Active Loans/Installments:
$installmentsStr
''';
  }
}
