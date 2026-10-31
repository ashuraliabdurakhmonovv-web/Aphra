import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as yandex;
import 'package:yandex_maps_mapkit_lite/ui_view.dart' as yandex_view;
import 'package:yandex_maps_mapkit_lite/yandex_map.dart';

import '../../domain/entities/place.dart';
import 'salon_photo.dart';

/// An embedded Yandex MapKit view for salons provided by the existing API.
class PlacesMap extends StatefulWidget {
  const PlacesMap({required this.places, this.onPlaceSelected, super.key});

  final List<Place> places;
  final ValueChanged<Place>? onPlaceSelected;

  @override
  State<PlacesMap> createState() => _PlacesMapState();
}

class _PlacesMapState extends State<PlacesMap> {
  static const _tashkent = yandex.Point(latitude: 41.3111, longitude: 69.2797);

  // MapKit's style format accepts a single string for `types` and `elements`.
  // `major_landmark` is the basemap layer that renders circular photo markers.
  static const _hidePhotoLandmarksStyle =
      '[{"types":"point","tags":{"all":["major_landmark"]},'
      '"elements":"label.icon","stylers":{"visibility":"off"}}]';

  yandex.MapWindow? _mapWindow;
  final _tapListeners = <_SalonTapListener>[];
  final _markerViews = <yandex_view.ViewProvider>[];
  var _mapRevision = 0;
  var _placesRevision = 0;

  @override
  void didUpdateWidget(covariant PlacesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) _showPlaces();
  }

  void _onMapCreated(yandex.MapWindow mapWindow) {
    _mapWindow = mapWindow;
    _configureMap(mapWindow.map);
    _showPlaces();
  }

  @override
  void reassemble() {
    super.reassemble();
    final map = _mapWindow?.map;
    if (map != null) _configureMap(map);
    // A native map may retain previously fetched tiles during hot reload.
    // Recreate it so the updated basemap style is requested from the start.
    if (mounted) setState(() => _mapRevision++);
  }

  void _configureMap(yandex.Map map) {
    map.mapType = yandex.MapType.VectorMap;
    map.nightModeEnabled = true;
    // This is a fallback for POIs not covered by a map style.
    map.poiLimit = 0;
    map.awesomeModelsEnabled = false;
    map.setMapStyle(_hidePhotoLandmarksStyle);
  }

  Future<void> _showPlaces() async {
    final mapWindow = _mapWindow;
    if (mapWindow == null) return;
    final revision = ++_placesRevision;

    final mappedPlaces = widget.places
        .where(
          (place) =>
              place.latitude >= -90 &&
              place.latitude <= 90 &&
              place.longitude >= -180 &&
              place.longitude <= 180,
        )
        .toList(growable: false);

    // MapKit snapshots ViewProvider widgets immediately. Decode the local
    // photos first so the snapshot includes them instead of white circles.
    await Future.wait(
      mappedPlaces
          .map((place) => SalonPhoto.previewAssets[place.id])
          .whereType<String>()
          .toSet()
          .map((asset) => precacheImage(AssetImage(asset), context)),
    );
    if (!mounted || revision != _placesRevision || _mapWindow != mapWindow) {
      return;
    }

    final map = mapWindow.map;

    _tapListeners.clear();
    _markerViews.clear();
    map.mapObjects.clear();
    for (final place in mappedPlaces) {
      final markerView = yandex_view.ViewProvider(
        id: 'salon-marker-${place.id}',
        cacheable: true,
        builder: () => _SalonMapMarker(place: place),
      );
      _markerViews.add(markerView);
      final placemark = map.mapObjects.addPlacemarkWithViewStyle(
        yandex.Point(latitude: place.latitude, longitude: place.longitude),
        markerView,
        const yandex.IconStyle(anchor: math.Point(0.5, 1), zIndex: 10),
      );
      final onPlaceSelected = widget.onPlaceSelected;
      if (onPlaceSelected != null) {
        final listener = _SalonTapListener(place, onPlaceSelected);
        placemark.addTapListener(listener);
        _tapListeners.add(listener);
      }
    }

    map.move(
      yandex.CameraPosition(
        _tashkent,
        zoom: mappedPlaces.isEmpty ? 12.5 : 11.5,
        azimuth: 0,
        tilt: 0,
      ),
      animation: const yandex.Animation(
        type: yandex.AnimationType.Smooth,
        duration: 0.25,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      YandexMap(key: ValueKey(_mapRevision), onMapCreated: _onMapCreated);
}

class _SalonTapListener implements yandex.MapObjectTapListener {
  const _SalonTapListener(this.place, this.onSelected);

  final Place place;
  final ValueChanged<Place> onSelected;

  @override
  bool onMapObjectTap(yandex.MapObject mapObject, yandex.Point point) {
    onSelected(place);
    return true;
  }
}

class _SalonMapMarker extends StatelessWidget {
  const _SalonMapMarker({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 148,
    height: 102,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 24,
          left: 54,
          child: Container(
            width: 94,
            height: 56,
            padding: const EdgeInsets.fromLTRB(31, 10, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330D172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              place.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF151B26),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
        Positioned(top: 0, left: 58, child: _RatingPill(rating: place.rating)),
        Positioned(
          left: 0,
          top: 14,
          child: Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x500D172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(child: SalonPhoto(place: place)),
          ),
        ),
        Positioned(
          left: 26,
          bottom: 1,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF0009A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Container(
    height: 27,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F0D172A),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF0009A), size: 16),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFF151B26),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
