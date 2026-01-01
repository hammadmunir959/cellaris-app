# MBM – Mobile Business Manager: Flutter Desktop Architecture

## Overview
MBM is a premium, enterprise-grade business management system for mobile retail and service centers. This document outlines the technical architecture, design philosophy, and implementation strategy for the Flutter desktop application.

## 1. Design Philosophy
- **Premium UI/UX**: Focused on a high-end, modern aesthetic using Material 3, glassmorphism, and smooth micro-animations.
- **Desktop-First**: Optimized for large screens (Windows, Linux) with appropriate spacing, keyboard navigation, and side-navigation layouts.
- **Enterprise Scalability**: Built with Clean Architecture principles to ensure the codebase remains maintainable as features grow.

## 2. Technical Stack
- **Framework**: [Flutter](https://flutter.dev/) (Desktop: Windows/Linux)
- **State Management**: [Riverpod](https://riverpod.dev/) (Functional, scalable, and reactive)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) (Declarative routing with named routes and deep linking support)
- **Icons**: [Lucide Icons](https://pub.dev/packages/lucide_icons) (Clean, consistent iconography)
- **Styling**: Custom Theme Extensions for Glassmorphism and bespoke design tokens.
- **Data Layer**: Mock API Service with deferred execution to simulate network latency.

## 3. Directory Structure
The project follows a feature-based Clean Architecture:

```text
lib/
├── core/
│   ├── theme/              # Light/Dark themes, Glassmorphism styles, Typography
│   ├── constants/          # Static strings, API endpoints, App-wide constants
│   ├── utils/              # Helper functions, formatters, validators
│   └── widgets/            # Global reusable UI components (PrimaryButton, GlassCard, etc.)
├── features/
│   ├── dashboard/          # KPI cards, charts, recent activity
│   ├── pos/                # Point of Sale workflow, cart, payment
│   ├── inventory/          # Product management, stock tracking
│   ├── repairs/            # Ticket management, status updates
│   ├── customers/          # CRM module
│   ├── suppliers/          # Supplier profiles & balances
│   ├── purchases/          # Phone purchase workflow
│   ├── returns/            # Returns & exchanges
│   ├── analytics/          # Business intelligence & reports
│   └── settings/           # App configuration, user profile
│       ├── view/           # UI Screens and Widgets
│       ├── controller/     # Riverpod providers/logic
│       └── model/          # Data classes and types
├── navigation/
│   └── app_router.dart     # GoRouter configuration
├── shared/
│   ├── sidebar/            # Collapsible navigation drawer
│   ├── navbar/             # Top action bar (search, profile)
│   └── layouts/            # Reusable AppLayout scaffold
├── services/
│   └── mock_api_service.dart # Mocked data source for all features
└── main.dart               # App entry point
```

## 4. Key Architectural Decisions

### State Management (Riverpod)
- Shared state (e.g., Theme mode, User session) will use global providers.
- Feature-specific state (e.g., Cart in POS) will use `NotifierProvider` or `StateProvider` scoped to the feature.
- Async data fetching will be handled by `FutureProvider` or `StreamProvider` interacting with the `MockApiService`.

### Navigation (GoRouter)
- Uses a central `AppRouter` class.
- Supports nested routes for the `AppLayout` (Sidebar + Content).
- Named routes for all major screens: `/dashboard`, `/pos`, `/inventory`, etc.

### UI Components & Theming
- **GlassCard**: A specialized card widget using `BackdropFilter` and semi-transparent gradients to achieve a premium look.
- **AppLayout**: A high-level scaffold that handles the Sidebar, Topbar, and smooth transitions between pages.
- **Theme Extensions**: Used to store custom colors (e.g., brand colors, glass gradients) that aren't natively in `ThemeData`.

## 5. Development Roadmap
1.  **Foundation**: Theme setup, global widgets, and navigation shell.
2.  **Core Modules**: Implementation of Dashboard and POS screens.
3.  **Operations**: Inventory, Repair Service, and Phone Purchase modules.
4.  **Reporting**: Analytics and Returns modules.
5.  **Final Polish**: Animations, desktop-specific optimizations (shortcuts), and dark mode refinements.
