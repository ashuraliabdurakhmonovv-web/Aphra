import 'package:hive_ce/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/place_model.dart';

abstract interface class PlaceLocalDataSource {
  List<PlaceModel> getCachedPlaces();
  Future<void> cachePlaces(List<PlaceModel> places);
}

final class PlaceLocalDataSourceImpl implements PlaceLocalDataSource {
  const PlaceLocalDataSourceImpl(this._box);
  final Box<PlaceModel> _box;
  @override
  List<PlaceModel> getCachedPlaces() {
    try {
      return _box.values.toList(growable: false);
    } on Object {
      throw const CacheException();
    }
  }

  @override
  Future<void> cachePlaces(List<PlaceModel> places) async {
    try {
      await _box.clear();
      await _box.addAll(places);
    } on Object {
      throw const CacheException();
    }
  }
}
