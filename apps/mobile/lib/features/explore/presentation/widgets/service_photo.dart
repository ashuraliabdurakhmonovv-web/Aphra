import '../../data/datasources/salon_preview_catalog.dart';

/// Mockup photos of demo catalog services; others use the catalog image.
abstract final class ServicePhoto {
  static const _assets = {
    'manicure': 'assets/images/services/manicure.jpg',
    'pedicure': 'assets/images/services/pedicure.jpg',
    'brows': 'assets/images/services/brows.jpg',
    'haircut': 'assets/images/home/service_haircut.jpg',
  };

  static String of(SalonService service) =>
      _assets[service.id] ?? service.imageAsset;
}
