  import 'package:flutter/material.dart';
  import 'package:yandex_mapkit/yandex_mapkit.dart';

  class AddMarkerDialog extends StatefulWidget {
    final Point point;
    final Function(String title, String description) onSave;

    const AddMarkerDialog({
      super.key,
      required this.point,
      required this.onSave,
    });

    @override
    State<AddMarkerDialog> createState() => _AddMarkerDialogState();
  }

  class _AddMarkerDialogState extends State<AddMarkerDialog> {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        title: const Text('Добавить метку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Координаты: ${widget.point.latitude}, ${widget.point.longitude}'),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
            ),
          ],
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
              );
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      );
    }

    @override
    void dispose() {
      _titleController.dispose();
      _descriptionController.dispose();
      super.dispose();
    }
  }
