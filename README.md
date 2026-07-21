# Finance Tracker (Flutter)

A complete personal finance management app.

## Features

- **Dashboard** — total balance across all accounts, monthly income/expense summary, 7-day cash flow bar chart, recent transactions
- **Transactions** — add/edit/delete income, expense, and account-to-account transfers; recurring transaction option (daily/weekly/monthly/yearly); notes and dates
- **Search & filters** — search by title/note, filter by type or category, grouped by day
- **Multiple accounts** — cash, bank, credit card, e-wallet, savings, each with its own running balance computed from opening balance + transactions
- **Custom categories** — separate income/expense categories with custom icon and color, fully editable
- **Budgets** — per-category spending limits (weekly/monthly/yearly) with progress bars and over-budget warnings
- **Reports** — expense breakdown pie chart, 6-month income vs. expense bar chart, percentage-by-category list, adjustable time range
- **Settings** — light/dark/system theme toggle, currency symbol selector
- **Local persistence** — all data (accounts, categories, transactions, budgets, preferences) is saved on-device via `shared_preferences`, so it survives app restarts with no backend required

## Project structure

```
lib/
  models/          # Transaction, Category, Account, Budget data classes
  providers/        # FinanceProvider: single source of truth + persistence
  screens/           # Dashboard, Transactions, Add/Edit, Budgets, Accounts, Categories, Reports, Settings
  widgets/           # Reusable UI: transaction tile, summary card, budget progress bar
  utils/              # Theme and currency/date formatters
main.dart
```

State management uses the `provider` package (`ChangeNotifier`), which is lightweight and easy to extend. Charts are built with `fl_chart`.

## Running the app

This project was written in this environment, which does not have the Flutter SDK installed, so it has not been run/compiled here — please build it locally:

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).
2. From this project's root folder:
   ```bash
   flutter pub get
   flutter run
   ```
3. To create a release build:
   ```bash
   flutter build apk        # Android
   flutter build ios        # iOS (requires macOS + Xcode)
   flutter build web        # Web
   ```

## Notes & possible extensions

- Data is stored locally only (no cloud sync/login). Adding Firebase or a REST backend would enable multi-device sync.
- Could add CSV/PDF export, bill reminders/notifications, or multi-currency conversion as next steps.
