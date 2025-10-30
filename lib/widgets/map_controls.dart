import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onRotateToNorth;
  final VoidCallback onMoveToLocation;

  const MapControls({
    super.key,
    required this.onRotateToNorth,
    required this.onMoveToLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Кнопка ориентации на север
        FloatingActionButton(
          heroTag: 'compass',
          onPressed: onRotateToNorth,
          tooltip: 'Ориентация на север',
          child: const Icon(Icons.navigation),
        ),
        const SizedBox(height: 16),
        // Кнопка местоположения
        FloatingActionButton(
          heroTag: 'location',
          onPressed: onMoveToLocation,
          tooltip: 'Моё местоположение',
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }
}