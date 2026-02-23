import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  String responseText = '';

  Future<void> sendRequest() async {
    final String from = fromController.text;
    final String to = toController.text;

    if (from.isEmpty || to.isEmpty) {
      setState(() {
        responseText = 'Заполните оба поля';
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:3000/route?from=$from&to=$to');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          responseText = 'Ответ: ${response.body}';
        });
        print('Ответ от сервера: ${response.body}');
      } else {
        setState(() {
          responseText = 'Ошибка сервера: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        responseText = 'Ошибка соединения: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Построить маршрут'),
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
              onPressed: sendRequest,
              child: const Text('Построить маршрут'),
            ),
            const SizedBox(height: 24),
            Text(responseText),
          ],
        ),
      ),
    );
  }
}