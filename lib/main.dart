import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yandex Maps Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

// Модель данных для метки
class MapMarker {
  final String id;
  final String title;
  final String description;
  final Point point;
  final DateTime createdAt;

  MapMarker({
    required this.id,
    required this.title,
    required this.description,
    required this.point,
    required this.createdAt,
  });

  // Конвертация в PlacemarkMapObject
  PlacemarkMapObject toPlacemark() {
    return PlacemarkMapObject(
      mapId: MapObjectId(id),
      point: point,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/location.png'),
          scale: 0.2,
        ),
      ),
      opacity: 1,
      direction: 0,
      text: title.isNotEmpty 
          ? PlacemarkText(
              text: title,
              style: const PlacemarkTextStyle(
                size: 12,
                color: Colors.black,
                placement: TextStylePlacement.top, // Размещение текста
              ),
            )
          : null,
    );
  }

  // Конвертация в Map для хранения
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Создание из Map
  static MapMarker fromMap(Map<String, dynamic> map) {
    return MapMarker(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      point: Point(
        latitude: map['latitude'],
        longitude: map['longitude'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}

// Хранилище меток
class MarkerStorage {
  static const String _storageKey = 'map_markers';

  // Получить все метки
  static Future<List<MapMarker>> getMarkers() async {
    // Здесь можно использовать SharedPreferences, Hive или другую БД
    // Для примера используем временное хранение в памяти
    return _tempStorage;
  }

  // Сохранить метку
  static Future<void> saveMarker(MapMarker marker) async {
    _tempStorage.add(marker);
    // В реальном приложении здесь будет сохранение в постоянное хранилище
  }

  // Удалить метку
  static Future<void> deleteMarker(String id) async {
    _tempStorage.removeWhere((marker) => marker.id == id);
  }

  // Временное хранилище в памяти (замените на реальное)
  static final List<MapMarker> _tempStorage = [
    MapMarker(
      id: 'static_placemark',
      title: 'Москва',
      description: 'Столица России',
      point: const Point(latitude: 55.751244, longitude: 37.618423),
      createdAt: DateTime.now(),
    ),
  ];
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  final List<MapMarker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  // Загрузка меток из хранилища
  Future<void> _loadMarkers() async {
    final markers = await MarkerStorage.getMarkers();
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
      _updateMapObjects();
    });
  }

  // Обновление объектов на карте
  void _updateMapObjects() {
    _mapObjects.clear();
    for (final marker in _markers) {
      _mapObjects.add(marker.toPlacemark());
    }
    setState(() {});
  }

  // Добавление новой метки
  void _addMarker(Point point) {
    showDialog(
      context: context,
      builder: (context) => AddMarkerDialog(
        point: point,
        onSave: (title, description) async {
          final newMarker = MapMarker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: description,
            point: point,
            createdAt: DateTime.now(),
          );

          await MarkerStorage.saveMarker(newMarker);
          await _loadMarkers(); // Перезагружаем метки
        },
      ),
    );
  }

  // Показать список всех меток
  void _showMarkersList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MarkersListBottomSheet(
        markers: _markers,
        onMarkerTap: (marker) {
          _mapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: marker.point,
                zoom: 15,
              ),
            ),
          );
          Navigator.pop(context);
        },
        onDeleteMarker: (marker) async {
          await MarkerStorage.deleteMarker(marker.id);
          await _loadMarkers();
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yandex Map Kit Full'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showMarkersList,
            tooltip: 'Список меток',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Добавление метки в центр карты
              _mapController?.getCameraPosition().then((cameraPosition) {
                _addMarker(cameraPosition.target);
              });
            },
            tooltip: 'Добавить метку в центр',
          ),
        ],
      ),
      body: YandexMap(
        onMapCreated: (YandexMapController controller) {
          _mapController = controller;
          print('Карта успешно создана!');
        },
        onMapTap: (Point point) {
          print('Тап по координатам: ${point.latitude}, ${point.longitude}');
          _addMarker(point);
        },
        mapObjects: _mapObjects,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _mapController?.moveCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(
                    target: Point(latitude: 55.751244, longitude: 37.618423),
                    zoom: 10,
                  ),
                ),
              );
            },
            child: const Icon(Icons.center_focus_strong),
            tooltip: 'Центрировать на Москве',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showMarkersList,
            child: const Icon(Icons.list),
            tooltip: 'Список меток',
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

// Диалог добавления новой метки
class AddMarkerDialog extends StatefulWidget {
  final Point point;
  final Function(String title, String description) onSave;

  const AddMarkerDialog({
    super.key,
    required this.point,
    required this.onSave,
  });

  @override
  State<AddMarkerDialog> createState() => _AddMarkerDialogState();
}

class _AddMarkerDialogState extends State<AddMarkerDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить метку'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Координаты: ${widget.point.latitude.toStringAsFixed(6)}, '
              '${widget.point.longitude.toStringAsFixed(6)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Описание',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              _titleController.text.trim(),
              _descriptionController.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// Bottom sheet со списком меток
class MarkersListBottomSheet extends StatelessWidget {
  final List<MapMarker> markers;
  final Function(MapMarker) onMarkerTap;
  final Function(MapMarker) onDeleteMarker;

  const MarkersListBottomSheet({
    super.key,
    required this.markers,
    required this.onMarkerTap,
    required this.onDeleteMarker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Метки (${markers.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: markers.isEmpty
                ? const Center(
                    child: Text('Нет сохраненных меток'),
                  )
                : ListView.builder(
                    itemCount: markers.length,
                    itemBuilder: (context, index) {
                      final marker = markers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.red),
                          title: Text(marker.title.isNotEmpty 
                              ? marker.title 
                              : 'Без названия'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (marker.description.isNotEmpty)
                                Text(marker.description),
                              Text(
                                '${marker.point.latitude.toStringAsFixed(4)}, '
                                '${marker.point.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () => onMarkerTap(marker),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onDeleteMarker(marker),
                            tooltip: 'Удалить метку',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}