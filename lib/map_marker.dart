import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapMarker {
  String id;
  String title;
  String description;
  double latitude;
  double longitude;
  double scale;
  int titleColorValue;
  String markerType;
  int createdAt;

  // Геттер для использования в UI: m.titleColor
  Color get titleColor => Color(titleColorValue);

  MapMarker({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.scale,
    required this.titleColorValue,
    required this.markerType,
    required this.createdAt,
  });

  // Из JSON (включая значения по умолчанию при отсутствии полей)
  factory MapMarker.fromJson(Map<String, dynamic> json) {
    // ✅ Список допустимых типов иконок (английские названия файлов)
    const validTypes = [
      'location',
      'home',
      'food',
      'work',
      'entertainment',
      'other',
      'education',
    ];
    
    String markerType = json['markerType']?.toString() ?? 'location';
    
    // ✅ Если тип не существует в списке, заменяем на дефолтный
    if (!validTypes.contains(markerType)) {
      print('⚠️ Неизвестный тип метки: $markerType, используем "location"');
      markerType = 'location';
    }
    
    return MapMarker(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 0.0,
      scale: (json['scale'] is num) ? (json['scale'] as num).toDouble() : 1.0,
      titleColorValue: json['titleColorValue'] is int
          ? json['titleColorValue'] as int
          : (json['titleColorValue'] is String
              ? int.tryParse(json['titleColorValue']) ?? Colors.black.value
              : Colors.black.value),
      markerType: markerType,
      createdAt: json['createdAt'] is int
          ? json['createdAt'] as int
          : DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'scale': scale,
      'titleColorValue': titleColorValue,
      'markerType': markerType,
      'createdAt': createdAt,
    };
  }

  @override
  String toString() => jsonEncode(toJson());

  // Конвертация в PlacemarkMapObject для отображения на карте
  PlacemarkMapObject toPlacemark() {
    return PlacemarkMapObject(
      mapId: MapObjectId(id),
      point: Point(latitude: latitude, longitude: longitude),
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/icons/$markerType.png'),
          scale: scale,
          anchor: const Offset(0.5, 0.5), // ✅ Центрирование иконки
        ),
      ),
      consumeTapEvents: true, // ✅ Предотвращает всплытие события
    );
  }
}