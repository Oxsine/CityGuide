import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoStorage {
  /// Получить директорию для фото приложения
  Future<Directory> get _photosDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }

  /// Сохранить фото в постоянное хранилище
  Future<String> savePhoto(String sourcePath) async {
    try {
      final photosDir = await _photosDirectory;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(sourcePath);
      final fileName = 'photo_$timestamp$extension';
      final sourceFile = File(sourcePath);
      final targetPath = '${photosDir.path}/$fileName';
      await sourceFile.copy(targetPath);
      print('✅ Фото сохранено: $targetPath');
      return targetPath;
    } catch (e) {
      print('❌ Ошибка сохранения фото: $e');
      rethrow;
    }
  }

  /// Удалить фото
  Future<void> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Фото удалено: $photoPath');
      }
    } catch (e) {
      print('❌ Ошибка удаления фото: $e');
    }
  }

  /// Удалить все фото метки
  Future<void> deleteMarkerPhotos(List<String> photoPaths) async {
    for (final photoPath in photoPaths) {
      await deletePhoto(photoPath);
    }
  }
}
