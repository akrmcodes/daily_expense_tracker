# 💸 Yemen expenese tracker

A modern, responsive personal finance management app built with **Flutter**, designed to organize your income and expenses into **folders**, **accounts**, and **transactions**. The app uses **Riverpod** for state management and **Hive** for persistent local storage — ensuring a smooth, fast, and consistent experience.

> 📱 Fully localized for Arabic (RTL layout) and structured using best practices in UI/UX, architecture, and component design.

---

## 🚀 Features

- ✅ Organize your financial data into **folders** (like "Travel", "Business", etc.)
- ✅ Each folder contains multiple **accounts** (like "Cash", "Bank", etc.)
- ✅ Each account tracks detailed **transactions** (with date, amount, type, notes)
- ✅ Add **income or expense** transactions with date picker
- ✅ Real-time **balance calculation** per account and folder
- ✅ Full **local persistence** using Hive (no data loss after restart)
- ✅ **Riverpod state management** for centralized, reactive UI updates
- ✅ Snackbar confirmations for actions (account creation, transaction addition)
- ✅ Dark theme with Material 3 design and RTL layout support
- ✅ Clean, modern UI following Flutter and UX best practices
- ✅ Search and filter (coming soon)

---

## 📸 Screenshots

> *(Replace these with actual screenshots)*

| Home Screen | Folder Details | Add Transaction |
|-------------|----------------|------------------|
| ![home](screenshots/home.png) | ![folder](screenshots/folder_details.png) | ![add_tx](screenshots/add_transaction.png) |

---

## 🛠️ Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/yemen-finance-manager.git
cd yemen-finance-manager
2. Install dependencies
bash
Copy
Edit
flutter pub get
3. Generate Hive Adapters (if needed)
bash
Copy
Edit
flutter packages pub run build_runner build
4. Run the app
bash
Copy
Edit
flutter run
📦 Dependencies
Package	Use
flutter_riverpod	State management
hive & hive_flutter	Local data persistence
path_provider	Access local storage paths
intl	Date formatting with locale support
flutter_localizations	Full Arabic + English localization

✅ Hive Adapters are created for: TransactionModel

📁 Folder Structure
bash
Copy
Edit
lib/
├── main.dart                         # App initialization + Hive setup
├── models/
│   └── transaction_model.dart        # Hive-compatible transaction model
├── providers/
│   └── app_state_provider.dart       # Riverpod AppStateNotifier
├── views/
│   ├── home_screen.dart              # Shows folders
│   ├── folder_details_screen.dart    # Shows accounts per folder
│   ├── add_transaction_screen.dart   # Form to add a transaction
│   ├── add_account_screen.dart       # Form to add a new account
│   └── account_details_screen.dart   # (Upcoming) List + manage transactions per account
├── widgets/
│   ├── balances_card.dart            # Reusable balance summary card
│   ├── account_list.dart             # Displays accounts within a folder
│   └── folder_list.dart              # Displays folder cards
🔮 Future Improvements
🔍 Search & filter transactions by type, date, or text

✏️ Edit / delete transactions

📊 Summary charts (income vs. expense)

☁️ Optional cloud sync (e.g., Firebase)

🔒 Biometric security

🌐 Multi-device sync

👨‍💻 Author
Built with ❤️ and attention to detail.
Need support or want to contribute? Open an issue or PR on GitHub.

📃 License
This project is open source and available under the MIT License.