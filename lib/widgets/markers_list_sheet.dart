import 'package:flutter/material.dart';
import '../map_marker.dart';

class MarkersListBottomSheet extends StatelessWidget {
  final List<MapMarker> markers;
  final void Function(MapMarker marker) onMarkerTap;
  final void Function(MapMarker marker) onEditMarker;
  final void Function(MapMarker marker) onDeleteMarker;

  const MarkersListBottomSheet({
    super.key,
    required this.markers,
    required this.onMarkerTap,
    required this.onEditMarker,
    required this.onDeleteMarker,
  });

  @override
  Widget build(BuildContext context) {
    if (markers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Нет сохранённых меток',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: markers.length,
      itemBuilder: (context, index) {
        final m = markers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              m.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: m.titleColor,
              ),
            ),
            subtitle: Text(
              '${m.description}\nТип: ${m.markerType}',
              style: const TextStyle(fontSize: 13),
            ),
            isThreeLine: true,
            onTap: () => onMarkerTap(m),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEditMarker(m),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDeleteMarker(m),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
