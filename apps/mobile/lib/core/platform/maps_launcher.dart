import 'package:url_launcher/url_launcher.dart';

/// Opens an external navigation application through the Google Maps URL API.
///
/// It intentionally does not request or persist the user's location: Google
/// Maps resolves the origin after the handoff. This temporary integration needs
/// no Google Maps SDK key and can be replaced by an in-app map later.
abstract interface class MapsLauncher {
  Future<bool> openDirections({
    String? address,
    double? latitude,
    double? longitude,
  });

  Future<bool> search(String query);
}

final class GoogleMapsLauncher implements MapsLauncher {
  @override
  Future<bool> openDirections({
    String? address,
    double? latitude,
    double? longitude,
  }) {
    final destination = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : address;
    if (destination == null || destination.trim().isEmpty) {
      return Future.value(false);
    }
    return launchUrl(
      directionsUri(destination),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<bool> search(String query) {
    if (query.trim().isEmpty) return Future.value(false);
    return launchUrl(searchUri(query), mode: LaunchMode.externalApplication);
  }

  static Uri directionsUri(String destination) => Uri.https(
    'www.google.com',
    '/maps/dir/',
    {'api': '1', 'destination': destination, 'travelmode': 'driving'},
  );

  static Uri searchUri(String query) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': query},
  );
}
