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
    return ListView(
      children: markers
          .map(
            (m) => ListTile(
              title: Text(m.title, style: TextStyle(color: m.titleColor)),
              subtitle: Text('${m.description}\n${m.markerType}'),
              isThreeLine: true,
              onTap: () => onMarkerTap(m),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => onEditMarker(m)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => onDeleteMarker(m)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
