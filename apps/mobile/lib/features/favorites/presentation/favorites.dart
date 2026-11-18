import 'package:flutter/foundation.dart';

import '../../cart/data/datasources/shop_preview_catalog.dart';
import '../../explore/data/datasources/place_preview_data.dart';
import '../../explore/data/datasources/salon_preview_catalog.dart';
import '../../explore/domain/entities/place.dart';

typedef SavedService = ({Place salon, SalonService service});
typedef SavedMaster = ({Place salon, SalonSpecialist master});

/// Favorites of one kind, remembering the order they were added in.
class FavoriteList<T> extends ChangeNotifier {
  FavoriteList(this._keyOf);

  /// Identifies an item, so a salon loaded again is still the same salon.
  final Object Function(T item) _keyOf;
  final _items = <Object, (T, int)>{};
  var _next = 0;

  int get length => _items.length;

  bool contains(T item) => _items.containsKey(_keyOf(item));

  /// The most recently added first.
  List<T> get newestFirst {
    final entries = _items.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (item, _) in entries) item];
  }

  void toggle(T item) {
    final key = _keyOf(item);
    if (_items.remove(key) == null) _items[key] = (item, _next++);
    notifyListeners();
  }

  /// Removes [item]; the returned callback puts it back in its place.
  VoidCallback remove(T item) {
    final key = _keyOf(item);
    final removed = _items.remove(key);
    notifyListeners();
    return () {
      if (removed == null || _items.containsKey(key)) return;
      _items[key] = removed;
      notifyListeners();
    };
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

/// Products, salons, services and masters the user saved. They live in
/// memory until favorites have an API.
class Favorites {
  final products = FavoriteList<ShopProduct>((product) => product.id);
  final salons = FavoriteList<Place>((salon) => salon.id);
  final services = FavoriteList<SavedService>(
    (saved) => (saved.salon.id, saved.service.id),
  );
  final masters = FavoriteList<SavedMaster>(
    (saved) => (saved.salon.id, saved.master.id),
  );

  late final Listenable changes = Listenable.merge([
    products,
    salons,
    services,
    masters,
  ]);

  int get count =>
      products.length + salons.length + services.length + masters.length;

  /// The favorites of the app.
  static final shared = Favorites();

  void clear() {
    products.clear();
    salons.clear();
    services.clear();
    masters.clear();
  }

  /// Saves some of the preview products, salons, services and masters, so
  /// that debug builds show a filled favorites page.
  void addPreview() {
    Place salon(int id) => PlacePreviewData.models
        .firstWhere((model) => model.id == id)
        .toEntity();
    SalonCatalog catalog(Place salon) => SalonPreviewCatalog.forPlace(salon)!;

    // Oldest first, as the page lists the newest first.
    for (final id in const [
      'olaplex_no3',
      'estee_double_wear',
      'estee_night_repair',
      'chanel_chance',
      'kerastase_chroma',
      'dior_lip_glow',
    ]) {
      products.toggle(ShopPreviewCatalog.product(id));
    }
    for (final id in const [-14, -7, -2, -1]) {
      salons.toggle(salon(id));
    }
    for (final (salonId, serviceId) in const [
      (-14, 'haircut'),
      (-7, 'facial'),
      (-4, 'brows'),
      (-2, 'styling'),
      (-2, 'pedicure'),
      (-1, 'lashes'),
      (-1, 'manicure'),
    ]) {
      final place = salon(salonId);
      services.toggle((
        salon: place,
        service: catalog(
          place,
        ).services.firstWhere((service) => service.id == serviceId),
      ));
    }
    for (final (salonId, masterId) in const [
      (-2, 'hair-second-1'),
      (-1, 'hair-0'),
      (-1, 'nail-0'),
    ]) {
      final place = salon(salonId);
      masters.toggle((
        salon: place,
        master: catalog(
          place,
        ).specialists.firstWhere((master) => master.id == masterId),
      ));
    }
  }
}
