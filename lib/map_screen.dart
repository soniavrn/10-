import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'dart:typed_data';
import 'dart:ui';

class MapScreen extends StatefulWidget {
  final double fromLat;
  final double fromLon;
  final double toLat;
  final double toLon;
  final String fromName;
  final String toName;

  const MapScreen({
    super.key,
    required this.fromLat,
    required this.fromLon,
    required this.toLat,
    required this.toLon,
    required this.fromName,
    required this.toName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<Uint8List> startMarkerImage;
  late Future<Uint8List> finishMarkerImage;

  @override
  void initState() {
    super.initState();
    startMarkerImage = _createCircleBitmap(Colors.green);
    finishMarkerImage = _createCircleBitmap(Colors.red);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.fromName} → ${widget.toName}'),
      ),
      body: FutureBuilder(
        future: Future.wait([startMarkerImage, finishMarkerImage]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final markers = snapshot.data as List<Uint8List>;

          return YandexMap(
            mapObjects: [
              PlacemarkMapObject(
                mapId: const MapObjectId('start'),
                point: Point(
                  latitude: widget.fromLat,
                  longitude: widget.fromLon,
                ),
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromBytes(markers[0]),
                  ),
                ),
              ),
              PlacemarkMapObject(
                mapId: const MapObjectId('finish'),
                point: Point(
                  latitude: widget.toLat,
                  longitude: widget.toLon,
                ),
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromBytes(markers[1]),
                  ),
                ),
              ),
              PolylineMapObject(
                mapId: const MapObjectId('route'),
                polyline: Polyline(points: [
                  Point(latitude: widget.fromLat, longitude: widget.fromLon),
                  Point(latitude: widget.toLat, longitude: widget.toLon),
                ]),
                strokeColor: Colors.blue,
                strokeWidth: 4,
              ),
            ],
            onMapCreated: (controller) {
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: Point(
                      latitude: (widget.fromLat + widget.toLat) / 2,
                      longitude: (widget.fromLon + widget.toLon) / 2,
                    ),
                    zoom: 5,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}