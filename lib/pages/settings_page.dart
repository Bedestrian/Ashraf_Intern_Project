import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _backendUrlController = TextEditingController();
  final TextEditingController _robotUrlController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedUrls();
  }

  Future<void> _loadSavedUrls() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      _backendUrlController.text = prefs.getString('pocketbase_url') ?? '';
      _robotUrlController.text = prefs.getString('robot_url') ?? '';
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUrls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pocketbase_url', _backendUrlController.text.trim());
    await prefs.setString('robot_url', _robotUrlController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URLs saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    _robotUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Backend Server (PocketBase) URL:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _backendUrlController,
              decoration: const InputDecoration(
                labelText:
                'Backend URL (e.g., http://192.168.1.100:8090)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Robot Server URL:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _robotUrlController,
              decoration: const InputDecoration(
                labelText:
                'Robot URL (e.g., http://192.168.1.150:5000)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUrls,
              child: const Text('Save URLs'),
            ),
          ],
        ),
      ),
    );
  }
}