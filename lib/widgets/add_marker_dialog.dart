import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class AddMarkerDialog extends StatefulWidget {
  final Point point;
  final String? initialTitle;
  final String? initialDescription;
  final double? initialScale;
  final Color? initialColor;
  final String? initialType;
  final void Function(String title, String description, double scale, Color color, String type) onSave;

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
  Color _titleColor = Colors.black;
  String _markerType = 'default';

  final List<String> _markerTypes = ['default', 'дом', 'работа', 'магазин', 'другое'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _scale = widget.initialScale ?? 1.0;
    _titleColor = widget.initialColor ?? Colors.black;
    _markerType = widget.initialType ?? 'default';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить метку'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _markerType,
              decoration: const InputDecoration(labelText: 'Тип метки'),
              items: _markerTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _markerType = v!),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Размер:'),
                Expanded(
                  child: Slider(
                    value: _scale,
                    min: 0.5,
                    max: 2.5,
                    onChanged: (v) => setState(() => _scale = v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Цвет названия:'),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Выбор цвета'),
                        content: Wrap(
                          children: [
                            for (final c in [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.purple])
                              GestureDetector(
                                onTap: () => Navigator.pop(context, c),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  width: 30,
                                  height: 30,
                                  color: c,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (color != null) setState(() => _titleColor = color);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    color: _titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Широта: ${widget.point.latitude.toStringAsFixed(5)}'),
            Text('Долгота: ${widget.point.longitude.toStringAsFixed(5)}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              _titleController.text,
              _descriptionController.text,
              _scale,
              _titleColor,
              _markerType,
            );
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
