import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'map_marker.dart';
import 'storage.dart';
import 'widgets/add_marker_dialog.dart';
import 'widgets/markers_list_sheet.dart';
import 'widgets/marker_details_sheet.dart';
import 'widgets/map_controls.dart';
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

  // ===== МЕТОДЫ РАБОТЫ С МЕТКАМИ =====
  
  Future<void> _showAddMarkerDialog(Point point) async {
    await showDialog(
      context: context,
      builder: (context) => AddMarkerDialog(
        point: point,
        onSave: (title, description, scale, color, type, photos) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          
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
            photos: photos,
          );

          markers.add(newMarker);
          await _storage.saveMarkers(markers);
          setState(() {});

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Метка "${newMarker.title}" добавлена'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editMarker(MapMarker marker) async {
    await showDialog(
      context: context,
      builder: (context) => AddMarkerDialog(
        point: Point(latitude: marker.latitude, longitude: marker.longitude),
        initialTitle: marker.title,
        initialDescription: marker.description,
        initialScale: marker.scale,
        initialColor: marker.titleColor,
        initialType: marker.markerType,
        initialPhotos: marker.photos,
        onSave: (title, description, scale, color, type, photos) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          
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
              photos: photos,
            );

            await _storage.saveMarkers(markers);
            setState(() {});

            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Метка обновлена'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteMarker(String markerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить метку?'),
        content: const Text('Это действие нельзя отменить'),
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
      
      markers.removeWhere((m) => m.id == markerId);
      await _storage.saveMarkers(markers);
      setState(() {});

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Метка удалена'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMarkerDetails(MapMarker marker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => MarkerDetailsSheet(
        marker: marker,
        onEdit: () {
          Navigator.pop(context);
          _editMarker(marker);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteMarker(marker.id);
        },
      ),
    );
  }

  // ===== СПИСОК МЕТОК =====
  
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
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Мои метки (${markers.length})',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MarkersListBottomSheet(
                    markers: markers,
                    onMarkerTap: (marker) async {
                      Navigator.pop(context);
                      
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

  // ===== УПРАВЛЕНИЕ КАРТОЙ =====
  
  Future<void> _rotateToNorth() async {
    if (_mapController != null) {
      final cameraPosition = await _mapController!.getCameraPosition();
      
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: cameraPosition.target,
            zoom: cameraPosition.zoom,
            azimuth: 0,
            tilt: 0,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.5,
        ),
      );
    }
  }

  Future<void> _moveToUserLocation() async {
    if (_mapController != null) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: _moscowCenter,
            zoom: 15.0,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.0,
        ),
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Функция местоположения в разработке'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ===== BUILD =====
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MapNote'),
        actions: [
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

          print('Карта инициализирована');
        },
        onMapTap: (point) => _showAddMarkerDialog(point),
        mapObjects: [
          ...markers.expand((marker) => [
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
              onTap: (_, __) => _showMarkerDetails(marker),
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
              onTap: (_, __) => _showMarkerDetails(marker),
            ),
          ]).toList(),
        ],
      ),
      floatingActionButton: MapControls(
        onRotateToNorth: _rotateToNorth,
        onMoveToLocation: _moveToUserLocation,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}