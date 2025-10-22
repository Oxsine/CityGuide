import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

part 'map_marker.g.dart';

@HiveType(typeId: 0)
class MapMarker extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  double latitude;

  @HiveField(4)
  double longitude;

  @HiveField(5)
  double scale;

  @HiveField(6)
  int titleColorValue;

  @HiveField(7)
  String markerType;

  @HiveField(8)
  int createdAt;

  MapMarker({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.scale = 1.0,
    this.markerType = 'default',
    this.titleColorValue = 0xFF000000,
    required this.createdAt,
  });

  Color get titleColor => Color(titleColorValue);

  PlacemarkMapObject toPlacemark() {
    return PlacemarkMapObject(
      mapId: MapObjectId(id),
      point: Point(latitude: latitude, longitude: longitude),
      opacity: 1,
      text: PlacemarkText(
        text: title,
        style: PlacemarkTextStyle(
          color: titleColor,
          placement: TextStylePlacement.top, // расположение текста над меткой
          size: 12,
        ),
      ),
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/icons/marker.png'),
          scale: scale,
        ),
      ),
    );
  }
}
