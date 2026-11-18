import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:yandex_maps_mapkit_lite/init.dart';
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';

import 'app/app.dart';
import 'core/di/service_locator.dart';
import 'features/favorites/presentation/favorites.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMapkit(
    apiKey: const String.fromEnvironment('YANDEX_MAPKIT_API_KEY'),
    locale: 'ru_RU',
  );
  mapkit.onStart();
  await EasyLocalization.ensureInitialized();
  await configureDependencies();
  // Preview salons and products exist only in debug builds; some of them
  // start saved so the favorites page is not empty.
  if (kDebugMode) Favorites.shared.addPreview();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('ru'),
      fallbackLocale: const Locale('ru'),
      // Russian needs its few/many forms: 2 отзыва, 5 отзывов.
      ignorePluralRules: false,
      child: const CosmeticMapApp(),
    ),
  );
}
