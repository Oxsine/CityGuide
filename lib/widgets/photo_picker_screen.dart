import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Экран для выбора фото (галерея или камера)
/// Возвращает путь к выбранному фото через Navigator.pop(context, path)
class PhotoPickerScreen extends StatelessWidget {
  const PhotoPickerScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        Navigator.pop(context, image.path);
      } else {
        Navigator.pop(context, null);
      }
    } catch (e) {
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор фото')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Из галереи'),
              onPressed: () => _pickImage(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Сделать фото'),
              onPressed: () => _pickImage(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
