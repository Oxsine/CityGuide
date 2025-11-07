import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // НОВЫЙ МЕТОД: Открыть в Яндекс Навигаторе
  Future<void> _openInYandexNavigator(BuildContext context) async {
    // URL схема для Яндекс Навигатора
    final yandexNavUrl = Uri.parse(
      'yandexnavi://build_route_on_map?lat_to=${marker.latitude}&lon_to=${marker.longitude}'
    );

    try {
      // Проверяем, установлен ли Яндекс Навигатор
      if (await canLaunchUrl(yandexNavUrl)) {
        await launchUrl(yandexNavUrl, mode: LaunchMode.externalApplication);
      } else {
        // Если не установлен, открываем веб-версию или маркет
        if (context.mounted) {
          final installChoice = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Яндекс Навигатор не установлен'),
              content: const Text('Выберите действие:'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'web'),
                  child: const Text('Открыть в браузере'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'install'),
                  child: const Text('Установить'),
                ),
              ],
            ),
          );

          if (installChoice == 'web') {
            // Открыть в Яндекс Картах (веб)
            final webUrl = Uri.parse(
              'https://yandex.ru/maps/?rtext=~${marker.latitude},${marker.longitude}&rtt=auto'
            );
            await launchUrl(webUrl, mode: LaunchMode.externalApplication);
          } 
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка открытия навигатора: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            
            // Координаты с кнопкой копирования
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
            
            Text(
              'Масштаб: ${marker.scale.toStringAsFixed(1)}x',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            
            // КНОПКИ ДЕЙСТВИЙ
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // НОВАЯ КНОПКА: Яндекс Навигатор
                ElevatedButton.icon(
                  onPressed: () => _openInYandexNavigator(context),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Навигатор'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                  ),
                ),
                              
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