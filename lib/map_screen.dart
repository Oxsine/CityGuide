import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'map_marker.dart';
import 'storage.dart';
import 'widgets/add_marker_dialog.dart';
import 'widgets/markers_list_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  final List<MapMarker> _markers = [];

  double _currentZoom = 10.0; // Начальный зум

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final markers = await MarkerStorage.getMarkers();
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
      _updateMapObjects(_currentZoom);
    });
  }

  void _updateMapObjects(double zoom) {
    _mapObjects.clear();

    // Масштаб иконки, ограниченный минимальным и максимальным значением
    double scale = (zoom / 15).clamp(0.1, 1.0);

    for (final marker in _markers) {
      _mapObjects.add(marker.toPlacemark(scale));
    }
    setState(() {});
  }

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
            latitude: point.latitude,
            longitude: point.longitude,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );
          await MarkerStorage.saveMarker(newMarker);
          await _loadMarkers();
        },
      ),
    );
  }

  void _showMarkersList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MarkersListBottomSheet(
        markers: _markers,
        onMarkerTap: (marker) {
          _mapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: Point(latitude: marker.latitude, longitude: marker.longitude),
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
        title: const Text('MapNote'),
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
              _mapController?.getCameraPosition().then((cameraPosition) {
                _addMarker(cameraPosition.target);
              });
            },
            tooltip: 'Добавить метку в центр',
          ),
        ],
      ),
      body: YandexMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onCameraPositionChanged: (CameraPosition cameraPosition, CameraUpdateReason reason, bool finished) {
          if (finished) {
            _currentZoom = cameraPosition.zoom / 4;
            _updateMapObjects(_currentZoom);
          }
        },
        onMapTap: _addMarker,
        mapObjects: _mapObjects,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
