import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'map_marker.dart';
import 'storage.dart';
import 'icon_processor.dart';
import 'widgets/add_marker_dialog.dart';
import 'widgets/markers_list_sheet.dart';
import 'widgets/marker_details_sheet.dart';
import 'widgets/map_controls.dart';
import 'settings_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Storage _storage = Storage();
  List<MapMarker> markers = [];
  YandexMapController? _mapController;
  Map<String, BitmapDescriptor> _iconCache = {}; // Кэш иконок
  PlacemarkMapObject? _userLocationPlacemark;
  BitmapDescriptor? _userLocationIcon;

  static const Point _moscowCenter = Point(
    latitude: 55.751244,
    longitude: 37.618423,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _loadUserLocationIcon();
  }

  Future<void> _loadMarkers() async {
    markers = await _storage.loadMarkers();
    // Предзагружаем все иконки
    await _preloadIcons();
    setState(() {});
    print('Загружено ${markers.length} меток');
  }

  Future<void> _loadUserLocationIcon() async {
    try {
      _userLocationIcon = await BitmapDescriptor.fromAssetImage(
        'assets/icons/user_location.png',
      );
    } catch (e) {
      print('Ошибка загрузки иконки местоположения: $e');
    }
  }

  // Предзагрузка всех иконок в кэш
  Future<void> _preloadIcons() async {
    _iconCache.clear();
    for (var marker in markers) {
      try {
        _iconCache[marker.id] = await _getMarkerIcon(marker);
      } catch (e) {
        print('Ошибка предзагрузки иконки для ${marker.id}: $e');
      }
    }
  }

  // Создание BitmapDescriptor из файла или из assets
  Future<BitmapDescriptor> _getMarkerIcon(MapMarker marker) async {
    if (marker.hasCustomIcon) {
      try {
        // Обрабатываем и нормализуем кастомную иконку
        final processedBytes = await IconProcessor.createStyledIcon(
          marker.customIconPath!,
          backgroundColor: Colors.white,
          addShadow: true,
          makeCircular: true,
        );
        return BitmapDescriptor.fromBytes(processedBytes);
      } catch (e) {
        print('Ошибка загрузки кастомной иконки: $e');
        // Fallback на стандартную иконку
        return BitmapDescriptor.fromAssetImage(
          'assets/icons/${marker.markerType}.png',
        );
      }
    } else {
      // Стандартная иконка из assets
      return BitmapDescriptor.fromAssetImage(
        'assets/icons/${marker.markerType}.png',
      );
    }
  }

  // ===== МЕТОДЫ РАБОТЫ С МЕТКАМИ =====

  Future<void> _showAddMarkerDialog(Point point) async {
    await showDialog(
      context: context,
      builder:
          (context) => AddMarkerDialog(
            point: point,
            onSave: (
              title,
              description,
              scale,
              color,
              type,
              photos,
              customIconPath,
            ) async {
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
                customIconPath: customIconPath,
              );

              markers.add(newMarker);
              await _storage.saveMarkers(markers);

              // Загружаем иконку для новой метки
              _iconCache[newMarker.id] = await _getMarkerIcon(newMarker);

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
            initialCustomIconPath: marker.customIconPath,
            onSave: (
              title,
              description,
              scale,
              color,
              type,
              photos,
              customIconPath,
            ) async {
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
                  customIconPath: customIconPath,
                );

                await _storage.saveMarkers(markers);

                // Обновляем иконку в кэше
                _iconCache[marker.id] = await _getMarkerIcon(markers[index]);

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
    final confirmed =
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

    if (confirmed) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      markers.removeWhere((m) => m.id == markerId);
      _iconCache.remove(markerId); // Удаляем из кэша
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
      builder:
          (context) => MarkerDetailsSheet(
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
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder:
                      (context, scrollController) => Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Мои метки (${markers.length})',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
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

                                    Future.delayed(
                                      const Duration(milliseconds: 500),
                                      () {
                                        _showMarkerDetails(marker);
                                      },
                                    );
                                  }
                                },
                                onEditMarker: (marker) {
                                  Navigator.pop(context);
                                  _editMarker(marker);
                                },
                                onDeleteMarker: (marker) async {
                                  final confirmed =
                                      await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Удалить метку?',
                                              ),
                                              content: Text(
                                                'Удалить "${marker.title}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Отмена'),
                                                ),
                                                ElevatedButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  child: const Text('Удалить'),
                                                ),
                                              ],
                                            ),
                                      ) ??
                                      false;

                                  if (confirmed) {
                                    final scaffoldMessenger =
                                        ScaffoldMessenger.of(context);

                                    markers.removeWhere(
                                      (m) => m.id == marker.id,
                                    );
                                    _iconCache.remove(marker.id);
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
    if (_mapController == null) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Включите службы геолокации в настройках'),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Настройки',
                onPressed: Geolocator.openLocationSettings,
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Разрешение на геолокацию отклонено'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Разрешение на геолокацию отклонено навсегда'),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Настройки',
                onPressed: Geolocator.openAppSettings,
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Определение местоположения...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final userLocation = Point(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 16.0),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.0,
        ),
      );

      // Обновляем или создаем маркер местоположения пользователя
      setState(() {
        if (_userLocationPlacemark == null) {
          _userLocationPlacemark = PlacemarkMapObject(
            mapId: const MapObjectId('user_location'),
            point: userLocation,
            opacity: 1.0,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image:
                    _userLocationIcon ??
                    BitmapDescriptor.fromAssetImage(
                      'assets/icons/user_location.png',
                    ),
                scale: 0.2,
              ),
            ),
          );
        } else {
          _userLocationPlacemark = _userLocationPlacemark!.copyWith(
            point: userLocation,
          );
        }
      });

      print('Местоположение: ${position.latitude}, ${position.longitude}');
      print('Точность: ${position.accuracy} метров');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Местоположение определено\nТочность: ${position.accuracy.toStringAsFixed(0)}м',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось определить местоположение: превышено время ожидания',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Ошибка геолокации: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
          if (_userLocationPlacemark != null) _userLocationPlacemark!,
          // Используем кэшированные иконки
          ...markers.expand((marker) {
            final icon = _iconCache[marker.id];
            if (icon == null) {
              // Если иконка еще не загружена, пропускаем метку
              return <MapObject>[];
            }

            return [
              PlacemarkMapObject(
                mapId: MapObjectId(marker.id),
                point: Point(
                  latitude: marker.latitude,
                  longitude: marker.longitude,
                ),
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: icon,
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
            ];
          }).toList(),
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
    _iconCache.clear();
    super.dispose();
  }
}
