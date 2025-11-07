import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../map_marker.dart';

class MarkersListBottomSheet extends StatefulWidget {
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
  State<MarkersListBottomSheet> createState() => _MarkersListBottomSheetState();
}

class _MarkersListBottomSheetState extends State<MarkersListBottomSheet> {
  String _searchQuery = '';
  List<MapMarker> _filteredMarkers = [];

  @override
  void initState() {
    super.initState();
    _filteredMarkers = widget.markers;
  }

  @override
  void didUpdateWidget(MarkersListBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _filterMarkers(_searchQuery);
  }

  void _filterMarkers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMarkers = widget.markers;
      } else {
        _filteredMarkers = widget.markers
            .where((marker) =>
                marker.title.toLowerCase().contains(query.toLowerCase()) ||
                marker.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _shareMarker(MapMarker marker) {
    final text = '''
📍 ${marker.title}

${marker.description.isNotEmpty ? '${marker.description}\n\n' : ''}Координаты:
Широта: ${marker.latitude.toStringAsFixed(6)}
Долгота: ${marker.longitude.toStringAsFixed(6)}

Google Maps: https://maps.google.com/?q=${marker.latitude},${marker.longitude}
Яндекс Карты: https://yandex.ru/maps/?ll=${marker.longitude},${marker.latitude}&z=16&pt=${marker.longitude},${marker.latitude}
''';

    Share.share(text, subject: marker.title);
  }

  void _copyCoordinates(MapMarker marker) {
    final coords = '${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: coords));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Координаты скопированы в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.markers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Нет сохранённых меток',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Нажмите на карту, чтобы добавить метку',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ПОИСК
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск меток...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _filterMarkers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
            ),
            onChanged: _filterMarkers,
          ),
        ),

        // Результаты поиска
        if (_searchQuery.isNotEmpty && _filteredMarkers.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Ничего не найдено',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуйте другой запрос',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),

        if (_filteredMarkers.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _filteredMarkers.length,
              itemBuilder: (context, index) {
                final marker = _filteredMarkers[index];
                
                return Dismissible(
                  key: Key(marker.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Показать подтверждение
                    return await showDialog<bool>(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    ) ?? false;
                  },
                  onDismissed: (direction) {
                    widget.onDeleteMarker(marker);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white, size: 32),
                        SizedBox(height: 4),
                        Text(
                          'Удалить',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      // Иконка типа метки
                      leading: CircleAvatar(
                        backgroundColor: marker.titleColor.withOpacity(0.2),
                        child: Icon(
                          _getIconForType(marker.markerType),
                          color: marker.titleColor,
                        ),
                      ),
                      
                      title: Text(
                        marker.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: marker.titleColor,
                        ),
                      ),
                      
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (marker.description.isNotEmpty)
                            Text(
                              marker.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          Text(
                            'Тип: ${_getTypeName(marker.markerType)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      
                      isThreeLine: true,
                      onTap: () => widget.onMarkerTap(marker),
                      
                      // ✅ МЕНЮ ДЕЙСТВИЙ
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              widget.onEditMarker(marker);
                              break;
                            case 'delete':
                              widget.onDeleteMarker(marker);
                              break;
                            case 'share':
                              _shareMarker(marker);
                              break;
                            case 'copy':
                              _copyCoordinates(marker);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Изменить'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 20),
                                SizedBox(width: 8),
                                Text('Поделиться'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'copy',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 20),
                                SizedBox(width: 8),
                                Text('Копировать координаты'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Удалить',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'food':
        return Icons.restaurant;
      case 'entertainment':
        return Icons.movie;
      case 'education':
        return Icons.school;
      case 'other':
        return Icons.help_outline;
      case 'location':
      default:
        return Icons.location_on;
    }
  }

  String _getTypeName(String type) {
    const typeNames = {
      'location': 'Локация',
      'home': 'Дом',
      'food': 'Еда',
      'work': 'Работа',
      'entertainment': 'Развлечение',
      'other': 'Разное',
      'education': 'Учеба',
    };
    return typeNames[type] ?? type;
  }
}