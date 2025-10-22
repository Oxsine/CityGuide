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

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    await MarkerStorage.init();
    final markers = await MarkerStorage.getMarkers();
    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
      _updateMapObjects();
    });
  }

  void _updateMapObjects() {
    _mapObjects.clear();
    for (final m in _markers) {
      _mapObjects.add(m.toPlacemark());
    }
    setState(() {});
  }

  void _addMarker(Point point) {
    showDialog(
      context: context,
      builder: (context) => AddMarkerDialog(
        point: point,
        onSave: (title, description, scale, color, type) async {
          final newMarker = MapMarker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: description,
            latitude: point.latitude,
            longitude: point.longitude,
            scale: scale,
            titleColorValue: color.value,
            markerType: type,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );
          await MarkerStorage.saveMarker(newMarker);
          await _loadMarkers();
        },
      ),
    );
  }

  void _editMarker(MapMarker marker) {
    showDialog(
      context: context,
      builder: (context) => AddMarkerDialog(
        point: Point(latitude: marker.latitude, longitude: marker.longitude),
        initialTitle: marker.title,
        initialDescription: marker.description,
        initialScale: marker.scale,
        initialColor: marker.titleColor,
        initialType: marker.markerType,
        onSave: (title, description, scale, color, type) async {
          marker
            ..title = title
            ..description = description
            ..scale = scale
            ..titleColorValue = color.value
            ..markerType = type;
          await MarkerStorage.updateMarker(marker);
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
          _mapController?.moveCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: Point(latitude: marker.latitude, longitude: marker.longitude),
              zoom: 15,
            ),
          ));
          Navigator.pop(context);
        },
        onDeleteMarker: (marker) async {
          await MarkerStorage.deleteMarker(marker.id);
          await _loadMarkers();
          if (context.mounted) Navigator.pop(context);
        },
        onEditMarker: _editMarker,
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
          IconButton(icon: const Icon(Icons.list), onPressed: _showMarkersList),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final pos = await _mapController?.getCameraPosition();
              if (pos != null) _addMarker(pos.target);
            },
          ),
        ],
      ),
      body: YandexMap(
        onMapCreated: (controller) => _mapController = controller,
        mapObjects: _mapObjects,
        onMapTap: _addMarker,
      ),
    );
  }
}
