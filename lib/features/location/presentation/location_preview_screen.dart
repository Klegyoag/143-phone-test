import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

class LocationPreviewScreen extends StatelessWidget {
  const LocationPreviewScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = 'Shared location',
  });

  final double latitude;
  final double longitude;
  final String title;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.onefourthree.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 54,
                      height: 54,
                      child: const Icon(Icons.favorite_rounded, size: 42, color: AppColors.rose),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: const [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.rose),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
