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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yandex Map Kit Full'),
        backgroundColor: Colors.red,
      ),
      body: YandexMap(
        onMapCreated: (YandexMapController controller) {
          _mapController = controller;
          print('Карта успешно создана!');
        },
        onMapTap: (Point point) {
          print('Тап по координатам: ${point.latitude}, ${point.longitude}');
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(
                target: Point(latitude: 55.751244, longitude: 37.618423), // Москва
                zoom: 10,
              ),
            ),
          );
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}