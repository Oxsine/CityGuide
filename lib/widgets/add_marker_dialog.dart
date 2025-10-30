import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddMarkerDialog extends StatefulWidget {
  final Point point;
  final void Function(String title, String description, double scale, Color color, String type, List<String> photos) onSave;

  final String? initialTitle;
  final String? initialDescription;
  final double? initialScale;
  final Color? initialColor;
  final String? initialType;
  final List<String>? initialPhotos;

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _scale = widget.initialScale ?? 0.5;
    _color = widget.initialColor ?? Colors.black;
    _photoPaths = widget.initialPhotos?.toList() ?? [];
    
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

  /// Добавить фото из галереи
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photoPaths.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора фото: $e')),
        );
      }
    }
  }

  /// Сделать фото камерой
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _photoPaths.add(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка камеры: $e')),
        );
      }
    }
  }

  /// Удалить фото
  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  /// Просмотр фото
  void _viewPhoto(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фотографии (${_photoPaths.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _takePhoto,
                      tooltip: 'Сделать фото',
                      color: Theme.of(context).primaryColor,
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: _pickImage,
                      tooltip: 'Выбрать из галереи',
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_photoPaths.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoPaths.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _viewPhoto(_photoPaths[index]),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              image: DecorationImage(
                                image: FileImage(File(_photoPaths[index])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            if (_photoPaths.isEmpty)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
                      const SizedBox(height: 4),
                      Text(
                        'Нет фотографий',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Масштаб
            const Text('Масштаб:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    label: _scale.toStringAsFixed(1),
                    value: _scale,
                    onChanged: (v) => setState(() => _scale = v),
                  ),
                ),
                Text(_scale.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 8),

            // Цвет
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

            // Тип метки
            DropdownButtonFormField<String>(
              value: _markerType,
              decoration: const InputDecoration(
                labelText: 'Тип метки',
                border: OutlineInputBorder(),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_typeNames[t] ?? t),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _markerType = v ?? 'location'),
            ),
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