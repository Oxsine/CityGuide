import 'package:hive/hive.dart';
import 'map_marker.dart';

class MarkerStorage {
  static final Box<MapMarker> _box = Hive.box<MapMarker>('markers');

  static Future<List<MapMarker>> getMarkers() async {
    return _box.values.toList();
  }

  static Future<void> saveMarker(MapMarker marker) async {
    await _box.put(marker.id, marker);
  }

  static Future<void> deleteMarker(String id) async {
    await _box.delete(id);
  }
}
