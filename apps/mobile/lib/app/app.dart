import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class CosmeticMapApp extends StatelessWidget {
  const CosmeticMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'app.name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }
}
