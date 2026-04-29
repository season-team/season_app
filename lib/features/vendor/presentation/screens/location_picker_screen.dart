import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/shared/widgets/custom_button.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  const LocationPickerScreen({super.key, this.initialLat = 24.7136, this.initialLng = 46.6753});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late ll.LatLng _selected;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selected = ll.LatLng(widget.initialLat, widget.initialLng);
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          _mapController.move(ll.LatLng(pos.latitude, pos.longitude), 13);
        }
      } catch (_) {
        // ignore when location not available
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.selectLocation, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selected,
          initialZoom: 12,
          onTap: (tapPosition, point) => setState(() => _selected = point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'season_app',
          ),
          MarkerLayer(markers: [
            Marker(
              point: _selected,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on, color: AppColors.secondary, size: 40),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: CustomButton(
            text: loc.confirm,
            onPressed: () => Navigator.pop(context, _selected),
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}


