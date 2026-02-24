import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RoutePlannerScreen(),
    );
  }
}

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  List<List<double>> _routePoints = [];
  bool _isLoading = false;

  Uint8List? _greenMarker;
  Uint8List? _redMarker;

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  Future<void> _createMarkers() async {
    _greenMarker = await _createCircleBitmap(Colors.green);
    _redMarker = await _createCircleBitmap(Colors.red);
    setState(() {});
  }

  Future<Uint8List> _createCircleBitmap(Color color) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(40, 40);
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(20, 20), 18, paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _buildRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Заполни оба поля')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _routePoints = [];
    });

    try {
      final url = Uri.parse(
        'http://10.0.2.2:3000/route?from=${_fromController.text}&to=${_toController.text}',
      );
      final response = await http.get(url);

      print('📡 Статус ответа: ${response.statusCode}');
      print('📦 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['from'] == null || data['to'] == null) {
          throw Exception('Сервер не вернул from или to');
        }

        setState(() {
          _routePoints = [
            [data['from']['lon'].toDouble(), data['from']['lat'].toDouble()],
            [data['to']['lon'].toDouble(), data['to']['lat'].toDouble()],
          ];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Маршрут построен: ${data['from']['name']} → ${data['to']['name']}')),
        );

        print('📍 Точки маршрута: $_routePoints');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Планировщик маршрута'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    labelText: 'Откуда',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    labelText: 'Куда',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _buildRoute,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Построить маршрут'),
                ),
                if (_routePoints.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Координаты:\n'
                      'Старт: ${_routePoints.first[1]}, ${_routePoints.first[0]}\n'
                      'Финиш: ${_routePoints.last[1]}, ${_routePoints.last[0]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _greenMarker == null || _redMarker == null
                ? const Center(child: CircularProgressIndicator())
                : YandexMap(
                    mapObjects: _buildMapObjects(),
                    onMapCreated: (controller) {
                      print('🗺️ Карта создана');
                      if (_routePoints.isNotEmpty) {
                        controller.moveCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: Point(
                                latitude: (_routePoints.first[1] + _routePoints.last[1]) / 2,
                                longitude: (_routePoints.first[0] + _routePoints.last[0]) / 2,
                              ),
                              zoom: 5,
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<MapObject> _buildMapObjects() {
    print('🔍 _buildMapObjects вызван');
    if (_routePoints.isEmpty) {
      print('⚠️ _routePoints пуст');
      return [];
    }
    if (_greenMarker == null || _redMarker == null) {
      print('⚠️ маркеры не готовы');
      return [];
    }

    final points = _routePoints
        .map((point) => Point(latitude: point[1], longitude: point[0]))
        .toList();
    print('✅ точки преобразованы: $points');

    try {
      return [
        PolylineMapObject(
          mapId: const MapObjectId('route'),
          polyline: Polyline(points: points),
          strokeColor: Colors.blue,
          strokeWidth: 4,
        ),
        PlacemarkMapObject(
          mapId: const MapObjectId('start'),
          point: points.first,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_greenMarker!),
            ),
          ),
        ),
        PlacemarkMapObject(
          mapId: const MapObjectId('end'),
          point: points.last,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_redMarker!),
            ),
          ),
        ),
      ];
    } catch (e) {
      print('❌ Ошибка при создании объектов карты: $e');
      return [];
    }
  }
}