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

  /// Получить путь к папке для фотографий
  Future<String> get _photosPath async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/marker_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir.path;
  }

  /// Получить файл JSON
  Future<File> get _localFile async {
    final path = await _localPath;
    final file = File('$path/$_fileName');
    print('JSON file path: ${file.path}');
    return file;
  }

  /// Скопировать фото в постоянное хранилище и вернуть новый путь
  Future<String> copyPhotoToStorage(String sourcePath) async {
    try {
      final File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Исходный файл не существует: $sourcePath');
      }

      final String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          sourcePath.split('/').last;
      final String photosDir = await _photosPath;
      final String newPath = '$photosDir/$fileName';

      await sourceFile.copy(newPath);
      print('Фото скопировано в: $newPath');

      return newPath;
    } catch (e) {
      print('Ошибка копирования фото: $e');
      rethrow;
    }
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
      final prettyJson = JsonEncoder.withIndent(
        '  ',
      ).convert(markers.map((marker) => marker.toJson()).toList());

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
      final markerIndex = markers.indexWhere((m) => m.id == markerId);
      if (markerIndex != -1) {
        await deletePhotos(markers[markerIndex].photos);
        markers.removeAt(markerIndex);
      }
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

  /// Удалить список фото-файлов
  Future<void> deletePhotos(List<String> photoPaths) async {
    for (final path in photoPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Ошибка удаления фото $path: $e');
      }
    }
  }
}
