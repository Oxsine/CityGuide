import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddMarkerDialog extends StatefulWidget {
  final Point point;
  final void Function(String title, String description, double scale, Color color, String type, List<String> photos, String? customIconPath) onSave;

  final String? initialTitle;
  final String? initialDescription;
  final double? initialScale;
  final Color? initialColor;
  final String? initialType;
  final List<String>? initialPhotos;
  final String? initialCustomIconPath;

  const AddMarkerDialog({
    super.key,
    required this.point,
    required this.onSave,
    this.initialTitle,
    this.initialDescription,
    this.initialScale,
    this.initialColor,
    this.initialType,
    this.initialPhotos,
    this.initialCustomIconPath,
  });

  @override
  State<AddMarkerDialog> createState() => _AddMarkerDialogState();
}

class _AddMarkerDialogState extends State<AddMarkerDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  double _scale = 0.5;
  Color _color = Colors.black;
  String _markerType = 'location';
  List<String> _photoPaths = [];
  String? _customIconPath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _types = [
    'location',
    'home',
    'food',
    'work',
    'entertainment',
    'other',
    'education',
  ];

  final Map<String, String> _typeNames = {
    'location': 'Локация',
    'home': 'Дом',
    'food': 'Еда',
    'work': 'Работа',
    'entertainment': 'Развлечение',
    'other': 'Разное',
    'education': 'Учеба',
  };

  final Map<String, IconData> _typeIcons = {
    'location': Icons.location_on,
    'home': Icons.home,
    'food': Icons.restaurant,
    'work': Icons.work,
    'entertainment': Icons.celebration,
    'other': Icons.place,
    'education': Icons.school,
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _scale = widget.initialScale ?? 0.5;
    _color = widget.initialColor ?? Colors.black;
    _photoPaths = widget.initialPhotos?.toList() ?? [];
    _customIconPath = widget.initialCustomIconPath;
    
    if (widget.initialType != null && _types.contains(widget.initialType)) {
      _markerType = widget.initialType!;
    } else {
      _markerType = 'location';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Выбрать пользовательскую иконку для метки
  Future<void> _pickCustomIcon() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _customIconPath = image.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Пользовательская иконка выбрана'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора иконки: $e')),
        );
      }
    }
  }

  /// Удалить пользовательскую иконку
  void _removeCustomIcon() {
    setState(() {
      _customIconPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Используется стандартная иконка'),
        duration: Duration(seconds: 2),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final hasCustomIcon = _customIconPath != null;

    return AlertDialog(
      title: Text(widget.initialTitle != null ? 'Редактировать метку' : 'Добавить метку'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Описание
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // === РАЗДЕЛ ВЫБОРА ИКОНКИ ===
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎨 Иконка метки',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (hasCustomIcon)
                  TextButton.icon(
                    onPressed: _removeCustomIcon,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Сбросить'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Превью текущей иконки
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCustomIcon ? Colors.blue : Colors.grey,
                  width: hasCustomIcon ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Превью иконки
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: hasCustomIcon
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_customIconPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            _typeIcons[_markerType] ?? Icons.location_on,
                            size: 50,
                            color: _color,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasCustomIcon ? 'Пользовательская иконка' : 'Стандартная иконка',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Кнопка выбора пользовательской иконки
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickCustomIcon,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Выбрать свою иконку'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (hasCustomIcon)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Используется своя иконка. Тип метки не влияет на отображение.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Масштаб иконки (УЛУЧШЕНО)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Размер иконки:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_scale * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 0.3,
                    max: 1.5,
                    divisions: 12,
                    label: '${(_scale * 100).toInt()}%',
                    value: _scale,
                    onChanged: (v) => setState(() => _scale = v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => _scale = 0.5),
                  tooltip: 'Сбросить',
                  iconSize: 20,
                ),
              ],
            ),
            // Подсказки по размеру
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Маленький (30%)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  'Средний (50%)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  'Большой (150%)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Цвет названия
            if (!hasCustomIcon) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Цвет названия:', style: TextStyle(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () async {
                      final newColor = await showDialog<Color>(
                        context: context,
                        builder: (_) => _ColorPickerDialog(currentColor: _color),
                      );
                      if (newColor != null) setState(() => _color = newColor);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Тип метки (только если нет кастомной иконки)
              DropdownButtonFormField<String>(
                value: _markerType,
                decoration: const InputDecoration(
                  labelText: 'Тип метки',
                  border: OutlineInputBorder(),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(_typeIcons[t], size: 20),
                              const SizedBox(width: 8),
                              Text(_typeNames[t] ?? t),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _markerType = v ?? 'location'),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              _titleController.text.trim(),
              _descriptionController.text.trim(),
              _scale,
              _color,
              _markerType,
              _photoPaths,
              _customIconPath,
            );
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

/// Диалог выбора цвета
class _ColorPickerDialog extends StatelessWidget {
  final Color currentColor;
  const _ColorPickerDialog({required this.currentColor});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
    ];
    
    return AlertDialog(
      title: const Text('Выбери цвет'),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: colors.map((c) {
          final isSelected = c == currentColor;
          return GestureDetector(
            onTap: () => Navigator.pop(context, c),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey,
                  width: isSelected ? 4 : 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}