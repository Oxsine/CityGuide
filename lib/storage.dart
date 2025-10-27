import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'map_marker.dart';

class Storage {
  static const String _fileName = 'markers.json';

  /// Получить путь к файлу JSON
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Получить файл JSON
  Future<File> get _localFile async {
    final path = await _localPath;
    final file = File('$path/$_fileName');
    print('JSON file path: ${file.path}');
    return file;
  }

  /// Загрузить все маркеры из JSON файла
  Future<List<MapMarker>> loadMarkers() async {
    try {
      final file = await _localFile;
      
      if (!await file.exists()) {
        print('JSON file does not exist yet, creating empty list');
        return [];
      }

      final String contents = await file.readAsString();
      print('Loaded JSON: $contents');
      
      if (contents.isEmpty) {
        return [];
      }

      final List<dynamic> decodedList = jsonDecode(contents);
      return decodedList
          .map((json) => MapMarker.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading markers: $e');
      return [];
    }
  }

  /// Сохранить все маркеры в JSON файл
  Future<bool> saveMarkers(List<MapMarker> markers) async {
    try {
      final file = await _localFile;
      
      // Красиво форматированный JSON для удобного редактирования
      final prettyJson = JsonEncoder.withIndent('  ').convert(
        markers.map((marker) => marker.toJson()).toList(),
      );
      
      await file.writeAsString(prettyJson);
      print('Saved ${markers.length} markers to ${file.path}');
      print('JSON content:\n$prettyJson');
      return true;
    } catch (e) {
      print('Error saving markers: $e');
      return false;
    }
  }

  /// Удалить конкретный маркер
  Future<bool> deleteMarker(String markerId) async {
    try {
      final markers = await loadMarkers();
      markers.removeWhere((marker) => marker.id == markerId);
      return await saveMarkers(markers);
    } catch (e) {
      print('Error deleting marker: $e');
      return false;
    }
  }

  /// Обновить конкретный маркер
  Future<bool> updateMarker(MapMarker updatedMarker) async {
    try {
      final markers = await loadMarkers();
      final index = markers.indexWhere((m) => m.id == updatedMarker.id);
      
      if (index != -1) {
        markers[index] = updatedMarker;
        return await saveMarkers(markers);
      }
      return false;
    } catch (e) {
      print('Error updating marker: $e');
      return false;
    }
  }

  /// Очистить все маркеры
  Future<bool> clearAllMarkers() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      print('Error clearing markers: $e');
      return false;
    }
  }

  /// Получить путь к файлу для отладки
  Future<String> getFilePath() async {
    final file = await _localFile;
    return file.path;
  }

  /// Получить количество меток
  Future<int> getMarkersCount() async {
    final markers = await loadMarkers();
    return markers.length;
  }
}