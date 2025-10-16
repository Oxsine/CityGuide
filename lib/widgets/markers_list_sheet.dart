import 'package:flutter/material.dart';
import '../map_marker.dart';

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                          title: Text(marker.title.isNotEmpty ? marker.title : 'Без названия'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (marker.description.isNotEmpty)
                                Text(marker.description),
                              Text(
                                '${marker.latitude.toStringAsFixed(4)}, ${marker.longitude.toStringAsFixed(4)}',
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
