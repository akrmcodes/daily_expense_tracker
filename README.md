# Daily Expense Tracker

Flutter-based personal finance app that keeps expenses and income organized into folders, accounts, and transactions. The app is fully localized for Arabic (RTL by default), works offline with Hive storage, and uses Riverpod for predictable state management.

## Features
- Folder → account → transaction hierarchy with real-time balances.
- Local-first data with Hive boxes (`transactions`, `folders`) and Riverpod streams.
- App lock with biometric/PIN (via `local_auth`) that re-locks when returning from background.
- Backup and restore to JSON/`.detb`, plus sharing through the system sheet.
- Reports to CSV or PDF (Arabic fonts embedded) with folder/account filters.
- Light/Dark themes using FlexColorScheme and Arabic-friendly typography.

## Tech Stack
- **Framework:** Flutter (Dart SDK ^3.8.x)
- **State management:** flutter_riverpod
- **Storage:** hive & hive_flutter
- **Security & device APIs:** local_auth, path_provider, file_picker
- **Sharing & reports:** share_plus, pdf, printing
- **Styling:** flex_color_scheme, google_fonts (Noto Naskh Arabic)

## Getting Started
1. **Prerequisites**
   - Flutter SDK installed and added to PATH.
   - A connected device or emulator.
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **(Optional) Regenerate Hive adapters** after editing models
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. **Run the app**
   ```bash
   flutter run
   ```
   The app starts in Arabic locale (`Locale('ar')`) with English also supported.

## Running Tests
```bash
flutter test
```

## Project Structure (high level)
```
lib/
├── main.dart                 # Bootstraps Hive, localization, themes, LockGate
├── models/                   # Hive models for transactions & folders
├── providers/                # Riverpod notifiers (app state, prefs, theme, etc.)
├── services/                 # Backup/import/export, reporting (CSV/PDF)
├── views/                    # Screens: home, folder/account details, reports, settings
├── widgets/                  # Reusable UI components (lists, cards, tiles)
├── security/                 # App lock gate + biometric unlock flow
└── theme/                    # Design tokens and theme setup
assets/fonts/                 # Noto Naskh Arabic (bundled for UI and PDFs)
```

## Data, Backup, and Restore
- Data lives locally in Hive boxes. Backups can be exported to Downloads (mobile/desktop) or any picked location. Imports support merge or replace flows and refresh the in-app state.
- Reports can be generated to CSV or PDF with optional folder/account filters; PDF output embeds Arabic fonts for correct rendering.

## Contributing
Pull requests and issues are welcome. Please format with Flutter defaults and run `flutter test` before submitting.

## License
MIT
