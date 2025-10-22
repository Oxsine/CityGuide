import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'map_marker.dart';
import 'map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MapMarkerAdapter());
  runApp(const MapNoteApp());
}

class MapNoteApp extends StatelessWidget {
  const MapNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}
