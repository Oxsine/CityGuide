import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 14.0;
    });
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    setState(() {
      _isDarkTheme = value;
    });
  }

  Future<void> _saveFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
    setState(() {
      _fontSize = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Секция: Внешний вид
          const Text(
            'Внешний вид',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Темная тема
          Card(
            child: SwitchListTile(
              title: const Text('Темная тема'),
              subtitle: const Text('Переключение между светлой и темной темой'),
              value: _isDarkTheme,
              onChanged: (value) async {
                await _saveTheme(value);
                // Перезагружаем приложение для применения темы
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Перезапустите приложение для применения темы'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              secondary: Icon(
                _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Размер шрифта
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Размер шрифта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Текущий размер: ${_fontSize.toStringAsFixed(0)} пт',
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 20.0,
                    divisions: 8,
                    label: _fontSize.toStringAsFixed(0),
                    onChanged: (value) async {
                      await _saveFontSize(value);
                    },
                  ),
                  Text(
                    'Пример текста с выбранным размером шрифта',
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Секция: О приложении
          const Text(
            'О приложении',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Версия'),
              subtitle: const Text('1.0.0'),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(
                Icons.map,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('MapNote'),
              subtitle: const Text('Приложение для заметок на карте'),
            ),
          ),
        ],
      ),
    );
  }
}