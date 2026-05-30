# Sora de - Repository Context

## Overview
**Sora de** is a Flutter-based mobile and web application designed for managing a gifting and photobooth business. It provides a comprehensive suite of tools for handling inventory, processing orders, managing finances, and generating reports. The application is built with a backend powered by Firebase, utilizing Firestore for database needs and Firebase Authentication for secure user access.

## Key Features & Functionality

### 1. Authentication
- **Secure Access**: Utilizes Firebase Authentication to manage user sign-up, login, and session handling.
- **Onboarding**: A Welcome screen for first-time users, managed via local shared preferences.

### 2. Dashboard
- **Business Overview**: A central hub providing key metrics and quick navigation to various parts of the application.

### 3. Inventory Management
- **Item Tracking**: Add, edit, and track inventory items (`InventoryItem`, `InventoryMeta`).
- **Stock Adjustments**: Record manual stock adjustments for precise inventory control (`StockAdjustment`).
- **Purchase History**: Log and view previous inventory purchases (`InventoryPurchase`).
- **Photo Management**: Upload and attach photos to inventory items, utilizing Firebase Storage (with REST fallback mechanisms).

### 4. Order Processing
- **Order Creation**: Create new customer orders for gifting or photobooth services (`GiftOrder`, `OrderLine`).
- **Order Presets**: Save and utilize presets for frequently ordered configurations (`OrderPreset`), speeding up the checkout process.
- **Order Tracking**: View past and current orders.

### 5. Financial Management
- **Revenue & Expenses**: Track income (`Revenue`) and log business expenses (`Expense`).
- **Financial Recording**: Dedicated screens for recording purchases and financial transactions.

### 6. Reporting & Analytics
- **Monthly Reports**: Generate comprehensive monthly business reports (`MonthlyReport`).
- **CSV Export**: Export report data to CSV format for external accounting (`report_csv_export.dart`).
- **Sharing**: Easily share reports with stakeholders using native share capabilities.

## Technical Architecture & Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: `provider` pattern, utilizing a central controller (`SoradeController`) to interact with the data layer.
- **Theming & UI**: Custom theming (`AppTheme`) with brand-specific colors (`brand_colors.dart`) and Material/Cupertino design principles.
- **Localization**: Supports multiple languages via `flutter_localizations` and custom l10n setups.

### Backend & Cloud Services (Firebase)
- **Database**: [Cloud Firestore](https://firebase.google.com/products/firestore) for scalable NoSQL data storage. Data interactions are abstracted behind a repository pattern (`FirestoreSoradeRepository`).
- **Authentication**: [Firebase Auth](https://firebase.google.com/products/auth) for user identity management.
- **Storage**: [Firebase Storage](https://firebase.google.com/products/storage) for storing inventory images and other media assets.

### Key Dependencies (from `pubspec.yaml`)
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`: Core Firebase integration.
- `provider`: State management.
- `shared_preferences`: Local persistent storage (e.g., app settings, welcome screen flag).
- `image_picker`: Capturing or selecting images for inventory.
- `share_plus`: Sharing files and text (like exported reports).
- `path_provider`: Accessing file system locations for CSV exports.
- `intl`: Internationalization and date/currency formatting (`money_format.dart`).
- `uuid`: Generating unique identifiers for domain models.
- `flutter_svg`: Rendering SVG vector graphics.
- `url_launcher`: Opening external URLs or handling specific URI schemes.
- `package_info_plus`: Accessing application metadata (version, build number).
- `http`: Network requests (used for custom storage REST endpoints).

## Project Structure
- `lib/core/`: Constants, branding, and core utilities.
- `lib/data/`: Data layer, containing repository interfaces, Firestore implementations, and data serializers.
- `lib/models/`: Domain models (e.g., `GiftOrder`, `InventoryItem`, `Expense`).
- `lib/screens/`: UI views and pages (e.g., `DashboardScreen`, `InventoryScreen`, `FinanceScreen`).
- `lib/services/`: Business logic services and external integrations (e.g., reporting, storage uploads, app updates).
- `lib/state/`: Application state management controllers (`SoradeController`).
- `lib/theme/`: UI theme configurations.
- `lib/widgets/`: Reusable UI components.
