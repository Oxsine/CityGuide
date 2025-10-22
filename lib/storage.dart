import 'package:hive/hive.dart';
import 'map_marker.dart';

class MarkerStorage {
  static const String _boxName = 'markersBox';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<MapMarker>(_boxName);
    }
  }

  static Box<MapMarker> get _box => Hive.box<MapMarker>(_boxName);

  static Future<void> saveMarker(MapMarker marker) async {
    await _box.put(marker.id, marker);
  }

  static Future<void> updateMarker(MapMarker marker) async {
    await marker.save();
  }

  static Future<void> deleteMarker(String id) async {
    await _box.delete(id);
  }

  static Future<List<MapMarker>> getMarkers() async {
    return _box.values.toList();
  }
}
