import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class IconProcessor {
  static const int STANDARD_ICON_SIZE = 80;
  static const int MAX_INPUT_SIZE = 512;

  static Future<Uint8List> processCustomIcon(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Файл не найден: $filePath');
    }

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Не удалось декодировать изображение');

    final resized = img.copyResize(
      image,
      width: STANDARD_ICON_SIZE,
      height: STANDARD_ICON_SIZE,
      interpolation: img.Interpolation.cubic,
    );

    return Uint8List.fromList(img.encodePng(resized));
  }

  static Future<Uint8List> createStyledIcon(
    String filePath, {
    bool addShadow = true,
    bool makeCircular = true,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }

      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Не удалось декодировать изображение');

      img.Image resized = img.copyResize(
        image,
        width: STANDARD_ICON_SIZE,
        height: STANDARD_ICON_SIZE,
        interpolation: img.Interpolation.cubic,
      );

      if (makeCircular) {
        resized = _makeCircular(resized); // Прозрачная обрезка
      }

      if (addShadow) {
        resized = _addShadow(resized);
      }

      return Uint8List.fromList(img.encodePng(resized));
    } catch (e) {
      print('Ошибка создания стилизованной иконки: $e');
      rethrow;
    }
  }

  /// Круглая маска с прозрачными краями
  static img.Image _makeCircular(img.Image image) {
    final size = image.width;
    final center = size ~/ 2;
    final radius = center;

    // создаём прозрачное изображение с альфа-каналом
    final circular = img.Image(
      width: size,
      height: size,
      numChannels: 4,
    );
    img.fill(circular, color: img.ColorRgba8(0, 0, 0, 0)); // полностью прозрачный фон

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - center;
        final dy = y - center;
        final distance = dx * dx + dy * dy;
        final radiusSquared = radius * radius;

        if (distance <= radiusSquared) {
          final pixel = image.getPixel(x, y);
          circular.setPixel(x, y, pixel);
        } else {
          // за пределами круга — полностью прозрачный пиксель
          circular.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        }
      }
    }

    return circular;
  }

  /// Добавление мягкой тени (если нужно)
  static img.Image _addShadow(img.Image image) {
    final size = image.width;
    final shadowOffset = 4;

    final shadowed = img.Image(
      width: size + shadowOffset * 2,
      height: size + shadowOffset * 2,
      numChannels: 4,
    );

    img.fill(shadowed, color: img.ColorRgba8(0, 0, 0, 0));

    // мягкая полупрозрачная тень
    img.fillCircle(
      shadowed,
      x: (size ~/ 2) + shadowOffset,
      y: (size ~/ 2) + shadowOffset,
      radius: size ~/ 2,
      color: img.ColorRgba8(0, 0, 0, 60),
    );

    // накладываем оригинальное изображение
    img.compositeImage(
      shadowed,
      image,
      dstX: shadowOffset,
      dstY: shadowOffset,
    );

    return shadowed;
  }

  static double getOptimalScale(double userScale) {
    if (userScale <= 0.5) {
      return userScale * 0.6;
    } else if (userScale <= 1.0) {
      return 0.3 + (userScale - 0.5) * 0.4;
    } else {
      return 0.5 + (userScale - 1.0) * 0.6;
    }
  }

  static Future<bool> validateIconFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      print('⚠️ Файл иконки слишком большой (${fileSize ~/ 1024} KB)');
      return false;
    }
    return true;
  }
}
