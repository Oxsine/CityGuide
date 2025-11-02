import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

class IconProcessor {
  // Стандартный размер иконки в пикселях
  static const int STANDARD_ICON_SIZE = 80;
  
  // Максимальный размер для загружаемых изображений
  static const int MAX_INPUT_SIZE = 512;

  /// Обработка кастомной иконки: изменение размера и оптимизация
  static Future<Uint8List> processCustomIcon(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }

      // Читаем файл
      final bytes = await file.readAsBytes();
      
      // Декодируем изображение
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      // Изменяем размер до стандартного
      img.Image resized = img.copyResize(
        image,
        width: STANDARD_ICON_SIZE,
        height: STANDARD_ICON_SIZE,
        interpolation: img.Interpolation.cubic,
      );

      // Кодируем обратно в PNG
      final processedBytes = img.encodePng(resized);
      
      return Uint8List.fromList(processedBytes);
    } catch (e) {
      print('Ошибка обработки иконки: $e');
      rethrow;
    }
  }

  /// Создание иконки с круглой рамкой и тенью (как стандартные иконки)
  static Future<Uint8List> createStyledIcon(String filePath, {
    Color? backgroundColor,
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
      
      if (image == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      // Изменяем размер
      img.Image resized = img.copyResize(
        image,
        width: STANDARD_ICON_SIZE,
        height: STANDARD_ICON_SIZE,
        interpolation: img.Interpolation.cubic,
      );

      if (makeCircular) {
        // Создаем круглую маску с белым фоном
        final bgColor = backgroundColor != null 
            ? img.ColorRgb8(backgroundColor.red, backgroundColor.green, backgroundColor.blue)
            : img.ColorRgb8(255, 255, 255);
        resized = _makeCircular(resized, bgColor);
      }

      if (addShadow) {
        // Добавляем небольшую тень
        resized = _addShadow(resized);
      }

      final processedBytes = img.encodePng(resized);
      return Uint8List.fromList(processedBytes);
    } catch (e) {
      print('Ошибка создания стилизованной иконки: $e');
      rethrow;
    }
  }

  /// Делаем изображение круглым
  static img.Image _makeCircular(img.Image image, img.ColorRgb8 backgroundColor) {
    final size = image.width;
    final center = size ~/ 2;
    final radius = center;

    // Создаем новое изображение с БЕЛЫМ фоном (не прозрачным)
    img.Image circular = img.Image(width: size, height: size);
    img.fill(circular, color: backgroundColor); // Заполняем белым

    // Рисуем круг с изображением
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - center;
        final dy = y - center;
        final distance = dx * dx + dy * dy;
        final radiusSquared = (radius - 2) * (radius - 2); // Небольшой отступ
        
        // Копируем только пиксели внутри круга
        if (distance <= radiusSquared) {
          final pixel = image.getPixel(x, y);
          circular.setPixel(x, y, pixel);
        }
        // Пиксели вне круга остаются белыми (backgroundColor)
      }
    }

    return circular;
  }

  /// Добавляем простую тень
  static img.Image _addShadow(img.Image image) {
    // Создаем изображение чуть больше для тени
    final size = image.width;
    final newSize = size + 8;
    final offset = 4;

    img.Image withShadow = img.Image(width: newSize, height: newSize);
    img.fill(withShadow, color: img.ColorRgba8(0, 0, 0, 0));

    // Рисуем полупрозрачную серую тень
    img.fillCircle(
      withShadow,
      x: newSize ~/ 2,
      y: newSize ~/ 2 + 2,
      radius: size ~/ 2,
      color: img.ColorRgba8(0, 0, 0, 50), // Черная тень с прозрачностью
    );

    // Копируем основное изображение поверх тени
    img.compositeImage(withShadow, image, dstX: offset, dstY: offset);

    return withShadow;
  }

  /// Получить оптимальный размер для отображения на карте
  static double getOptimalScale(double userScale) {
    // Нормализуем пользовательский масштаб
    // userScale от 0.3 до 1.5 -> результат от 0.3 до 0.8
    // Ограничиваем максимальный размер, чтобы иконки не закрывали всю область
    
    if (userScale <= 0.5) {
      return userScale * 0.6; // 0.3 -> 0.18, 0.5 -> 0.3
    } else if (userScale <= 1.0) {
      return 0.3 + (userScale - 0.5) * 0.4; // 0.5 -> 0.3, 1.0 -> 0.5
    } else {
      return 0.5 + (userScale - 1.0) * 0.6; // 1.0 -> 0.5, 1.5 -> 0.8
    }
  }

  /// Проверка и предупреждение о размере файла
  static Future<bool> validateIconFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return false;
      }

      final fileSize = await file.length();
      
      // Предупреждаем, если файл больше 5 МБ
      if (fileSize > 5 * 1024 * 1024) {
        print('ПРЕДУПРЕЖДЕНИЕ: Файл иконки слишком большой (${fileSize ~/ 1024} KB)');
        return false;
      }

      return true;
    } catch (e) {
      print('Ошибка валидации файла: $e');
      return false;
    }
  }
}