import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  bool isLoading = false;

  Future<void> sendRequest() async {
    final String from = fromController.text.trim();
    final String to = toController.text.trim();

    if (from.isEmpty || to.isEmpty) {
      _showSnackBar('Заполни оба поля');
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:3000/route?from=$from&to=$to');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              fromLat: data['from']['lat'],
              fromLon: data['from']['lon'],
              toLat: data['to']['lat'],
              toLon: data['to']['lon'],
              fromName: data['from']['name'],
              toName: data['to']['name'],
            ),
          ),
        );
      } else {
        _showSnackBar('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Ошибка соединения: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Планировщик маршрута'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: 'Откуда',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: 'Куда',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : sendRequest,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Построить маршрут'),
            ),
          ],
        ),
      ),
    );
  }
}