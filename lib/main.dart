import 'dart:async';

import 'package:another_iptv_player/core/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_iptv_player/services/service_locator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'controllers/locale_provider.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/branding_controller.dart';
import 'controllers/update_controller.dart';
import 'screens/app_initializer_screen.dart';
import 'services/cache_policy_service.dart';
import 'services/performance_service.dart';
import 'services/config_service.dart';
import 'services/announcement_service.dart';
import 'widgets/maintenance_banner.dart';
import 'widgets/update_startup_check.dart';
import 'l10n/app_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'l10n/supported_languages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Enable true fullscreen mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
  
  // Lock orientation to landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await PerformanceService.track('startup_setup', setupServiceLocator);
  unawaited(CachePolicyService().cleanupTemporaryCache());
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistController()),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => BrandingController()..load()),
        ChangeNotifierProvider(create: (_) => ConfigService()..initialize()),
        ChangeNotifierProvider(create: (_) => AnnouncementService()..initialize()),
        ChangeNotifierProvider(create: (_) => UpdateController()..loadState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final config = context.watch<ConfigService>().config;

    return MaterialApp(
      locale: localeProvider.locale,
      supportedLocales:
      supportedLanguages.map((lang) => Locale(lang['code'])).toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: config.branding.appName,
      theme: themeManager.currentThemeData,
      themeMode: ThemeMode.dark,
      builder: (context, child) => FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: child ?? const SizedBox.shrink(),
      ),
      home: UpdateStartupCheck(
        child: MaintenanceBanner(child: const AppInitializerScreen()),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
