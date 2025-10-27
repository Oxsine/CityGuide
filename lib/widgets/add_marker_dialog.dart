import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class AddMarkerDialog extends StatefulWidget {
  final Point point;
  final void Function(String title, String description, double scale, Color color, String type) onSave;

  final String? initialTitle;
  final String? initialDescription;
  final double? initialScale;
  final Color? initialColor;
  final String? initialType;

  const AddMarkerDialog({
    super.key,
    required this.point,
    required this.onSave,
    this.initialTitle,
    this.initialDescription,
    this.initialScale,
    this.initialColor,
    this.initialType,
  });

  @override
  State<AddMarkerDialog> createState() => _AddMarkerDialogState();
}

class _AddMarkerDialogState extends State<AddMarkerDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  double _scale = 1.0;
  Color _color = Colors.black;
  String _markerType = 'location'; // ✅ Английское название файла

  // ✅ Английские названия файлов (без .png)
  final List<String> _types = [
    'location',
    'home',
    'food',
    'work',
    'entertainment',
    'other',
    'education',
  ];

  // ✅ Русские названия для отображения пользователю
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
    _scale = widget.initialScale ?? 1.0;
    _color = widget.initialColor ?? Colors.black;
    
    // ✅ Проверяем, что initialType существует в списке
    if (widget.initialType != null && _types.contains(widget.initialType)) {
      _markerType = widget.initialType!;
    } else {
      _markerType = 'location'; // дефолтное значение
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить метку'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Масштаб:'),
                Expanded(
                  child: Slider(
                    min: 0.5,
                    max: 2.5,
                    divisions: 4,
                    label: _scale.toStringAsFixed(1),
                    value: _scale,
                    onChanged: (v) => setState(() => _scale = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Цвет:'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final newColor = await showDialog<Color>(
                      context: context,
                      builder: (_) => _ColorPickerDialog(currentColor: _color),
                    );
                    if (newColor != null) setState(() => _color = newColor);
                  },
                  child: CircleAvatar(backgroundColor: _color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _markerType,
              decoration: const InputDecoration(labelText: 'Тип метки'),
              items: _types
                  .map((t) => DropdownMenuItem(
                        value: t, // ✅ Английское значение (имя файла)
                        child: Text(_typeNames[t] ?? t), // ✅ Русское отображение
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
              _markerType, // ✅ Передаем английское название
            );
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

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
    ];
    return AlertDialog(
      title: const Text('Выбери цвет'),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: colors
            .map(
              (c) => GestureDetector(
                onTap: () => Navigator.pop(context, c),
                child: CircleAvatar(backgroundColor: c, radius: 18),
              ),
            )
            .toList(),
      ),
    );
  }
}