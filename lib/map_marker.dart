import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

part 'map_marker.g.dart';

@HiveType(typeId: 0)
class MapMarker {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final int createdAt;

  MapMarker({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  Point get point => Point(latitude: latitude, longitude: longitude);

  PlacemarkMapObject toPlacemark(double scale) {
    return PlacemarkMapObject(
      mapId: MapObjectId(id),
      point: point,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/location.png'),
          scale: scale,
        ),
      ),
      opacity: 1,
      direction: 0,
      text: title.isNotEmpty 
          ? PlacemarkText(
              text: title,
              style: const PlacemarkTextStyle(
                size: 12,
                color: Colors.black,
                placement: TextStylePlacement.top,
              ),
            )
          : null,
    );
  }

  // Другие методы...
}


