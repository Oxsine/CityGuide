import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../map_marker.dart';

class MarkerDetailsSheet extends StatelessWidget {
  final MapMarker marker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MarkerDetailsSheet({
    super.key,
    required this.marker,
    required this.onEdit,
    required this.onDelete,
  });

  void _shareMarker(BuildContext context) {
    final text = '''
📍 ${marker.title}

${marker.description.isNotEmpty ? '${marker.description}\n\n' : ''}Координаты:
Широта: ${marker.latitude.toStringAsFixed(6)}
Долгота: ${marker.longitude.toStringAsFixed(6)}

Google Maps: https://maps.google.com/?q=${marker.latitude},${marker.longitude}
Яндекс Карты: https://yandex.ru/maps/?ll=${marker.longitude},${marker.latitude}&z=16&pt=${marker.longitude},${marker.latitude}
''';

    Share.share(text, subject: marker.title);
  }

  void _copyCoordinates(BuildContext context) {
    final coords = '${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: coords));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Координаты скопированы'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    marker.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: marker.titleColor,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    marker.markerType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            
            if (marker.description.isNotEmpty) ...[
              Text(
                marker.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            
            // ✅ Координаты с кнопкой копирования
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Координаты: ${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyCoordinates(context),
                  tooltip: 'Копировать',
                ),
              ],
            ),

            
            // ✅ КНОПКИ ДЕЙСТВИЙ
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _shareMarker(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Поделиться'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Изменить'),
                ),
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Удалить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}