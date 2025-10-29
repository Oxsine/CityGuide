import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'map_marker.dart';
import 'storage.dart';
import 'widgets/add_marker_dialog.dart';
import 'widgets/markers_list_sheet.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Storage _storage = Storage();
  List<MapMarker> markers = [];
  YandexMapController? _mapController;

  // Стартовая позиция: Москва, Красная площадь
  static const Point _moscowCenter = Point(
    latitude: 55.751244,
    longitude: 37.618423,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    markers = await _storage.loadMarkers();
    setState(() {});
    print('Загружено ${markers.length} меток');
  }

  Future<void> _showAddMarkerDialog(Point point) async {
    print('Нажатие на карту: lat=${point.latitude}, lon=${point.longitude}');

    await showDialog(
      context: context,
      builder:
          (context) => AddMarkerDialog(
            point: point,
            onSave: (title, description, scale, color, type) async {
              final newMarker = MapMarker(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title.isEmpty ? 'Новая метка' : title,
                description: description,
                latitude: point.latitude,
                longitude: point.longitude,
                scale: scale,
                titleColorValue: color.value,
                markerType: type,
                createdAt: DateTime.now().millisecondsSinceEpoch,
              );

              print('Создана метка: ${newMarker.title}');
              print('Тип иконки: ${newMarker.markerType}');

              markers.add(newMarker);
              await _storage.saveMarkers(markers);

              print('Всего меток: ${markers.length}');

              setState(() {});

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Метка "${newMarker.title}" добавлена'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
    );
  }

  Future<void> _editMarker(MapMarker marker) async {
    await showDialog(
      context: context,
      builder:
          (context) => AddMarkerDialog(
            point: Point(
              latitude: marker.latitude,
              longitude: marker.longitude,
            ),
            initialTitle: marker.title,
            initialDescription: marker.description,
            initialScale: marker.scale,
            initialColor: marker.titleColor,
            initialType: marker.markerType,
            onSave: (title, description, scale, color, type) async {
              // Обновляем существующую метку
              final index = markers.indexWhere((m) => m.id == marker.id);
              if (index != -1) {
                markers[index] = MapMarker(
                  id: marker.id,
                  title: title.isEmpty ? 'Метка' : title,
                  description: description,
                  latitude: marker.latitude,
                  longitude: marker.longitude,
                  scale: scale,
                  titleColorValue: color.value,
                  markerType: type,
                  createdAt: marker.createdAt,
                );

                await _storage.saveMarkers(markers);
                setState(() {});

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Метка обновлена'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Future<void> _deleteMarker(
    String markerId, {
    bool showConfirmation = true,
  }) async {
    bool confirmed = true;

    // Подтверждение удаления
    if (showConfirmation) {
      confirmed =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Удалить метку?'),
                  content: const Text('Это действие нельзя отменить'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
          ) ??
          false;
    }

    if (confirmed) {
      markers.removeWhere((m) => m.id == markerId);
      await _storage.saveMarkers(markers);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Метка удалена'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showMarkerDetails(MapMarker marker) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Цвет фона из темы
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
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
                      ? Colors.grey[800] // ✅ Темный фон для темной темы
                      : Colors.grey[200], // ✅ Светлый фон для светлой темы
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  marker.markerType,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color, // ✅ Цвет текста из темы
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
          Text(
            'Координаты: ${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Масштаб: ${marker.scale.toStringAsFixed(1)}x',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteMarker(marker.id);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _editMarker(marker);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Изменить'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _showMarkersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor, // ✅ Используем цвет темы
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Заголовок
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor, // ✅ Цвет разделителя из темы
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Мои метки (${markers.length})',
                        style: Theme.of(context).textTheme.headlineSmall, // ✅ Стиль из темы
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Список меток
                Expanded(
                  child: MarkersListBottomSheet(
                    markers: markers,
                    onMarkerTap: (marker) async {
                      // Закрыть список
                      Navigator.pop(context);
                      
                      // Переместить камеру к метке
                      if (_mapController != null) {
                        await _mapController!.moveCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: Point(
                                latitude: marker.latitude,
                                longitude: marker.longitude,
                              ),
                              zoom: 15.0,
                            ),
                          ),
                          animation: const MapAnimation(
                            type: MapAnimationType.smooth,
                            duration: 1.0,
                          ),
                        );
                        
                        // Показать детали метки
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _showMarkerDetails(marker);
                        });
                      }
                    },
                    onEditMarker: (marker) {
                      Navigator.pop(context);
                      _editMarker(marker);
                    },
                    onDeleteMarker: (marker) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Удалить метку?'),
                          content: Text('Удалить "${marker.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Отмена'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Удалить'),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (confirmed) {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        
                        markers.removeWhere((m) => m.id == marker.id);
                        await _storage.saveMarkers(markers);
                        
                        // Обновляем и список и главный экран
                        setState(() {});
                        setModalState(() {});

                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Метка удалена'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Поворот карты на север (азимут 0)
  Future<void> _rotateToNorth() async {
    if (_mapController != null) {
      // Получаем текущую позицию камеры
      final cameraPosition = await _mapController!.getCameraPosition();

      // Поворачиваем на север (azimuth = 0)
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: cameraPosition.target,
            zoom: cameraPosition.zoom,
            azimuth: 0, // ✅ Север
            tilt: 0, // ✅ Убираем наклон
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.5,
        ),
      );

      print('Карта повернута на север');
    }
  }

  // ✅ Переместиться к местоположению пользователя
  Future<void> _moveToUserLocation() async {
    if (_mapController != null) {
      try {
        // Получаем текущее местоположение (требует разрешений)
        // Пока используем Москву как пример
        // TODO: Добавьте плагин geolocator для реального местоположения

        await _mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(
              target: _moscowCenter, // ✅ Замените на реальное местоположение
              zoom: 15.0,
            ),
          ),
          animation: const MapAnimation(
            type: MapAnimationType.smooth,
            duration: 1.0,
          ),
        );

        print('Перемещение к местоположению пользователя');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Функция местоположения в разработке'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Ошибка получения местоположения: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось получить местоположение'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MapNote'),
        actions: [
          // if (markers.isNotEmpty)
          //   Center(
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 16),
          //       child: Text('Меток: ${markers.length}'),
          //     ),
          //   ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Настройки',
          ),

          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showMarkersList,
            tooltip: 'Список меток',
          ),
        ],
      ),
      body: YandexMap(
        onMapCreated: (YandexMapController controller) async {
          _mapController = controller;

          await controller.moveCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(target: _moscowCenter, zoom: 12.0),
            ),
            animation: const MapAnimation(
              type: MapAnimationType.smooth,
              duration: 1.0,
            ),
          );

          print('Карта инициализирована. Позиция: Москва');
          print('Меток на карте: ${markers.length}');
        },
        onMapTap: (point) => _showAddMarkerDialog(point),
        mapObjects: [
          ...markers.expand((marker) {
            print('=== ОТЛАДКА МЕТКИ ===');
            print('ID: ${marker.id}');
            print('Title: ${marker.title}');
            print('Type: ${marker.markerType}');
            print('Path: assets/icons/${marker.markerType}.png');
            print('Scale: ${marker.scale}');
            print('Coordinates: ${marker.latitude}, ${marker.longitude}');
            print('==================');

            return [
              PlacemarkMapObject(
                mapId: MapObjectId(marker.id),
                point: Point(
                  latitude: marker.latitude,
                  longitude: marker.longitude,
                ),
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage(
                      'assets/icons/${marker.markerType}.png',
                    ),
                    scale: marker.scale,
                    anchor: const Offset(0.5, 0.5),
                  ),
                ),
                opacity: 1.0,
                consumeTapEvents: true,
                onTap: (PlacemarkMapObject self, Point point) {
                  print('Нажатие на метку: ${marker.title}');
                  _showMarkerDetails(marker);
                },
              ),
              PlacemarkMapObject(
                mapId: MapObjectId('text_${marker.id}'),
                point: Point(
                  latitude: marker.latitude,
                  longitude: marker.longitude,
                ),
                text: PlacemarkText(
                  text: marker.title,
                  style: PlacemarkTextStyle(
                    size: 10,
                    color: marker.titleColor,
                    placement: TextStylePlacement.bottom,
                    offset: 15,
                  ),
                ),
                consumeTapEvents: true,
                onTap: (PlacemarkMapObject self, Point point) {
                  print('Нажатие на текст метки: ${marker.title}');
                  _showMarkerDetails(marker);
                },
              ),
            ];
          }).toList(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Кнопка ориентации на север
          FloatingActionButton(
            heroTag: 'compass',
            onPressed: _rotateToNorth,
            tooltip: 'Ориентация на север',
            child: const Icon(Icons.navigation),
          ),
          const SizedBox(height: 16),
          // Кнопка местоположения
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _moveToUserLocation,
            tooltip: 'Моё местоположение',
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
