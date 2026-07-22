# Graph Report - yourcashier  (2026-07-23)

## Corpus Check
- 99 files · ~358,841 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 762 nodes · 727 edges · 83 communities (68 shown, 15 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ccbc3347`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]

## God Nodes (most connected - your core abstractions)
1. `Create()` - 10 edges
2. `MessageHandler()` - 10 edges
3. `WndProc()` - 9 edges
4. `_MyApplication` - 7 edges
5. `HWND` - 7 edges
6. `WindowClassRegistrar` - 7 edges
7. `Destroy()` - 7 edges
8. `MessageHandler()` - 6 edges
9. `AppDelegate` - 5 edges
10. `wWinMain()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `GetClientArea()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp

## Communities (83 total, 15 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.08
Nodes (34): RegisterPlugins(), PluginRegistry, Point, RECT, OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable() (+26 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (30): package:dodolanku/core/utils/currency_formatter.dart, package:dodolanku/core/utils/qris_generator.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/scanner/providers/scanner_provider.dart, package:dodolanku/features/settings/repositories/settings_repository.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, package:dodolanku/features/scanner/widgets/print_dialog.dart (+22 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (26): copyGlobalDb, DatabaseService, Directory, dispose, Exception, File, _initAutoNetworkSync, initDb (+18 more)

### Community 3 - "Community 3"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, fl_register_plugins(), FlView, GApplication, gboolean, gchar, GObject, GtkApplication (+14 more)

### Community 4 - "Community 4"
Cohesion: 0.10
Nodes (19): class, DartProject, _In_, _In_opt_, MessageHandler(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments() (+11 more)

### Community 5 - "Community 5"
Cohesion: 0.08
Nodes (23): package:dodolanku/core/database_service.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/dashboard/providers/dashboard_provider.dart, package:dodolanku/features/debt/providers/debt_provider.dart, package:dodolanku/features/orders/providers/orders_provider.dart, package:dodolanku/features/scanner/providers/scanner_provider.dart, package:dodolanku/features/scanner/repositories/product_repository.dart, package:dodolanku/features/settings/providers/profile_provider.dart (+15 more)

### Community 6 - "Community 6"
Cohesion: 0.09
Nodes (21): package:dodolanku/core/utils/qris_generator.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/settings/providers/profile_provider.dart, package:dodolanku/features/settings/repositories/settings_repository.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, package:mobile_scanner/mobile_scanner.dart, package:image_picker/image_picker.dart (+13 more)

### Community 7 - "Community 7"
Cohesion: 0.10
Nodes (19): package:dodolanku/core/utils/currency_formatter.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/dashboard/providers/dashboard_provider.dart, package:dodolanku/features/scanner/repositories/product_repository.dart, package:dodolanku/features/settings/providers/profile_provider.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, AppShimmer (+11 more)

### Community 8 - "Community 8"
Cohesion: 0.10
Nodes (19): package:dodolanku/core/database_service.dart, package:dodolanku/core/models/product_model.dart, package:dodolanku/core/models/transaction_model.dart, package:dodolanku/features/orders/repositories/transaction_repository.dart, package:dodolanku/features/scanner/models/cart_item_model.dart, package:dodolanku/features/scanner/repositories/product_repository.dart, package:flutter_riverpod/flutter_riverpod.dart, addToCart (+11 more)

### Community 9 - "Community 9"
Cohesion: 0.10
Nodes (19): package:dodolanku/core/services/print_service.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/settings/repositories/settings_repository.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, package:print_bluetooth_thermal/print_bluetooth_thermal.dart, build, buildDeviceCard (+11 more)

### Community 10 - "Community 10"
Cohesion: 0.10
Nodes (19): package:dodolanku/core/models/product_model.dart, package:dodolanku/core/utils/currency_formatter.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/dashboard/providers/dashboard_provider.dart, package:dodolanku/features/scanner/repositories/product_repository.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, _addNewNonBarcode (+11 more)

### Community 11 - "Community 11"
Cohesion: 0.11
Nodes (18): package:dodolanku/core/config/app_config.dart, package:dodolanku/core/services/permission_service.dart, package:flutter/material.dart, package:mobile_scanner/mobile_scanner.dart, package:dodolanku/core/services/audio_service.dart, package:dodolanku/core/widgets/app_scanner_viewfinder.dart, AppBarcodeScanner, _AppBarcodeScannerState (+10 more)

### Community 12 - "Community 12"
Cohesion: 0.11
Nodes (17): package:flutter/material.dart, package:dodolanku/core/services/update_service.dart, package:dodolanku/features/dashboard/views/dashboard_page.dart, package:dodolanku/features/debt/views/debt_page.dart, package:dodolanku/features/orders/views/orders_page.dart, package:dodolanku/features/scanner/views/scanner_page.dart, package:dodolanku/features/settings/views/settings_page.dart, build (+9 more)

### Community 13 - "Community 13"
Cohesion: 0.11
Nodes (17): package:dodolanku/core/utils/currency_formatter.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/orders/providers/orders_provider.dart, package:dodolanku/features/orders/repositories/transaction_repository.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, AppCard, build (+9 more)

### Community 14 - "Community 14"
Cohesion: 0.11
Nodes (17): package:dodolanku/core/models/product_model.dart, package:dodolanku/core/utils/currency_formatter.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/scanner/repositories/product_repository.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, AppCard, AppIconAvatar (+9 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (16): package:dodolanku/core/utils/currency_formatter.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/debt/providers/debt_provider.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, AppCard, build, Center (+8 more)

### Community 16 - "Community 16"
Cohesion: 0.12
Nodes (16): core/services/gdrive_service.dart, core/theme.dart, features/navigation/views/navigation_shell.dart, build, package:flutter_dotenv/flutter_dotenv.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, didChangeAppLifecycleState (+8 more)

### Community 17 - "Community 17"
Cohesion: 0.12
Nodes (15): package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/settings/providers/profile_provider.dart, package:dodolanku/features/settings/repositories/settings_repository.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, build, dispose, Expanded (+7 more)

### Community 18 - "Community 18"
Cohesion: 0.14
Nodes (10): Any, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, Bool, AppDelegate, Bool, AppDelegate (+2 more)

### Community 19 - "Community 19"
Cohesion: 0.13
Nodes (14): dart:ui, dart:developer, package:dodolanku/core/database_service.dart, package:dodolanku/core/services/permission_service.dart, package:dodolanku/core/utils/currency_formatter.dart, package:dodolanku/features/scanner/models/cart_item_model.dart, package:flutter/services.dart, package:print_bluetooth_thermal/print_bluetooth_thermal.dart (+6 more)

### Community 20 - "Community 20"
Cohesion: 0.14
Nodes (13): package:flutter/material.dart, Align, AnimatedBuilder, AppScannerViewfinder, _AppScanningLaserAnimation, _AppScanningLaserAnimationState, _AppViewfinderPainter, build (+5 more)

### Community 21 - "Community 21"
Cohesion: 0.15
Nodes (12): dart:io, package:flutter/material.dart, package:http/http.dart, package:path/path.dart, package:sqflite/sqflite.dart, package:dodolanku/core/config/database_config.dart, package:google_sign_in/google_sign_in.dart, package:googleapis/drive/v3.dart (+4 more)

### Community 22 - "Community 22"
Cohesion: 0.15
Nodes (12): package:dodolanku/core/utils/currency_formatter.dart, package:flutter/material.dart, package:flutter/services.dart, _AppFormBottomSheet, _AppFormBottomSheetState, AppFormField, build, Container (+4 more)

### Community 23 - "Community 23"
Cohesion: 0.18
Nodes (10): package:flutter/material.dart, AnimatedBuilder, AppShimmer, _AppShimmerState, build, dispose, initState, LinearGradient (+2 more)

### Community 24 - "Community 24"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 25 - "Community 25"
Cohesion: 0.20
Nodes (9): package:dodolanku/core/database_service.dart, package:dodolanku/core/services/print_service.dart, package:flutter_riverpod/flutter_riverpod.dart, getIsAutoPrint, getPaperSize, setAutoPrint, setPaperSize, SettingsRepository (+1 more)

### Community 26 - "Community 26"
Cohesion: 0.22
Nodes (8): dart:convert, package:flutter/material.dart, package:http/http.dart, package:dodolanku/core/widgets/app_modal.dart, package:package_info_plus/package_info_plus.dart, package:url_launcher/url_launcher.dart, launchUrl, UpdateService

### Community 27 - "Community 27"
Cohesion: 0.22
Nodes (8): package:dodolanku/core/services/print_service.dart, package:dodolanku/core/widgets/app_widgets.dart, package:dodolanku/features/scanner/providers/scanner_provider.dart, package:flutter/material.dart, Container, showPrintDialog, SizedBox, Text

### Community 28 - "Community 28"
Cohesion: 0.25
Nodes (7): package:flutter/material.dart, AppProductCard, AppStatCard, build, Container, GestureDetector, SizedBox

### Community 29 - "Community 29"
Cohesion: 0.25
Nodes (7): package:dodolanku/features/orders/repositories/transaction_repository.dart, package:dodolanku/features/scanner/providers/scanner_provider.dart, package:dodolanku/features/scanner/repositories/product_repository.dart, package:flutter_riverpod/flutter_riverpod.dart, package:dodolanku/features/dashboard/models/dashboard_stats_model.dart, DashboardData, DashboardNotifier

### Community 30 - "Community 30"
Cohesion: 0.25
Nodes (7): package:dodolanku/features/settings/repositories/settings_repository.dart, package:flutter/foundation.dart, package:flutter_riverpod/flutter_riverpod.dart, build, copyWith, ProfileNotifier, ProfileState

### Community 31 - "Community 31"
Cohesion: 0.29
Nodes (6): DatabaseSchema, debt_notes, products, receipt_config, transaction_items, transactions

### Community 32 - "Community 32"
Cohesion: 0.29
Nodes (6): package:flutter/material.dart, AppSettingsSection, AppSettingsTile, build, Column, ListTile

### Community 33 - "Community 33"
Cohesion: 0.29
Nodes (6): package:dodolanku/core/models/transaction_model.dart, package:dodolanku/features/orders/repositories/transaction_repository.dart, package:dodolanku/features/scanner/providers/scanner_provider.dart, package:flutter_riverpod/flutter_riverpod.dart, OrdersNotifier, TransactionWithItems

### Community 34 - "Community 34"
Cohesion: 0.29
Nodes (4): RegisterGeneratedPlugins(), FlutterPluginRegistry, NSWindow, MainFlutterWindow

### Community 35 - "Community 35"
Cohesion: 0.29
Nodes (3): RunnerTests, RunnerTests, XCTestCase

### Community 36 - "Community 36"
Cohesion: 0.29
Nodes (6): package:dodolanku/main.dart, package:flutter_test/flutter_test.dart, package:sqflite_common_ffi/sqflite_ffi.dart, package:flutter_riverpod/flutter_riverpod.dart, main, ProviderScope

### Community 37 - "Community 37"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 38 - "Community 38"
Cohesion: 0.33
Nodes (5): dart:async, package:connectivity_plus/connectivity_plus.dart, dispose, listenConnectionChange, NetworkService

### Community 39 - "Community 39"
Cohesion: 0.33
Nodes (5): package:flutter/services.dart, CurrencyInputFormatter, formatEditUpdate, formatRupiah, TextEditingValue

### Community 40 - "Community 40"
Cohesion: 0.33
Nodes (5): package:flutter/material.dart, AppIconAvatar, AppInitialAvatar, build, CircleAvatar

### Community 41 - "Community 41"
Cohesion: 0.33
Nodes (5): package:flutter/material.dart, AppInfoBadge, AppStatusBadge, build, Container

### Community 42 - "Community 42"
Cohesion: 0.33
Nodes (5): package:flutter/material.dart, AppAlertCard, AppCard, build, SizedBox

### Community 43 - "Community 43"
Cohesion: 0.33
Nodes (5): package:dodolanku/core/database_service.dart, package:dodolanku/features/debt/models/debt_model.dart, package:flutter_riverpod/flutter_riverpod.dart, package:dodolanku/features/debt/repositories/debt_repository.dart, DebtNotifier

### Community 44 - "Community 44"
Cohesion: 0.33
Nodes (5): package:dodolanku/core/database_service.dart, package:dodolanku/features/debt/models/debt_model.dart, package:flutter_riverpod/flutter_riverpod.dart, DebtRepository, DebtRepositoryImpl

### Community 45 - "Community 45"
Cohesion: 0.33
Nodes (5): package:dodolanku/core/database_service.dart, package:dodolanku/core/models/transaction_model.dart, package:flutter_riverpod/flutter_riverpod.dart, TransactionRepository, TransactionRepositoryImpl

### Community 46 - "Community 46"
Cohesion: 0.33
Nodes (5): package:dodolanku/core/database_service.dart, package:dodolanku/core/models/product_model.dart, package:flutter_riverpod/flutter_riverpod.dart, ProductRepository, ProductRepositoryImpl

### Community 47 - "Community 47"
Cohesion: 0.40
Nodes (4): images, info, author, version

### Community 48 - "Community 48"
Cohesion: 0.40
Nodes (4): images, info, author, version

### Community 49 - "Community 49"
Cohesion: 0.40
Nodes (4): AppTheme, ThemeData, package:flutter/material.dart, package:google_fonts/google_fonts.dart

### Community 50 - "Community 50"
Cohesion: 0.40
Nodes (4): _calculateCRC16, extractMerchantName, makeDynamic, QrisGenerator

### Community 51 - "Community 51"
Cohesion: 0.40
Nodes (4): package:flutter/material.dart, AppSearchBar, build, TextField

### Community 52 - "Community 52"
Cohesion: 0.40
Nodes (4): package:flutter/material.dart, AppSectionHeader, build, Row

### Community 53 - "Community 53"
Cohesion: 0.40
Nodes (4): package:flutter/material.dart, AppToast, show, SizedBox

### Community 54 - "Community 54"
Cohesion: 0.40
Nodes (4): images, info, author, version

### Community 55 - "Community 55"
Cohesion: 0.40
Nodes (4): Build APK (Release & Size Optimized), code:bash (flutter build apk --split-per-abi --release --obfuscate --sp), code:bash (flutter build apk --release --obfuscate --split-debug-info=b), Dodolanku (YourCashier)

### Community 56 - "Community 56"
Cohesion: 0.50
Nodes (3): DatabaseSeeders, receipt_config, package:sqflite/sqflite.dart

### Community 58 - "Community 58"
Cohesion: 0.50
Nodes (3): package:flutter/foundation.dart, package:audioplayers/audioplayers.dart, AudioService

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (3): dart:developer, package:permission_handler/permission_handler.dart, PermissionService

### Community 60 - "Community 60"
Cohesion: 0.50
Nodes (3): package:dodolanku/core/models/product_model.dart, DashboardData, TopProduct

### Community 61 - "Community 61"
Cohesion: 0.50
Nodes (3): CartItem, copyWith, ScanHistoryItem

## Knowledge Gaps
- **577 isolated node(s):** `java.configuration.updateBuildConfiguration`, `flutter_export_environment.sh script`, `SBFrame`, `SBDebugger`, `UIApplication` (+572 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `OnCreate()` connect `Community 0` to `Community 4`?**
  _High betweenness centrality (0.002) - this node is a cross-community bridge._
- **What connects `java.configuration.updateBuildConfiguration`, `flutter_export_environment.sh script`, `SBFrame` to the rest of the system?**
  _578 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.08130081300813008 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06451612903225806 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Should `Community 3` be split into smaller, more focused modules?**
  _Cohesion score 0.09401709401709402 - nodes in this community are weakly interconnected._
- **Should `Community 4` be split into smaller, more focused modules?**
  _Cohesion score 0.09846153846153846 - nodes in this community are weakly interconnected._