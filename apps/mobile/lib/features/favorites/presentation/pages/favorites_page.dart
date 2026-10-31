import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('favorites.title'.tr())),
    body: Center(child: Text('favorites.empty'.tr())),
  );
}
