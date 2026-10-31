import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:yandex_maps_mapkit_lite/init.dart';
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';

import 'app/app.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMapkit(
    apiKey: const String.fromEnvironment('YANDEX_MAPKIT_API_KEY'),
    locale: 'ru_RU',
  );
  mapkit.onStart();
  await EasyLocalization.ensureInitialized();
  await configureDependencies();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('ru'),
      fallbackLocale: const Locale('ru'),
      child: const CosmeticMapApp(),
    ),
  );
}
