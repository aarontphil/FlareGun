import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  bool get hasLocation => _lastPosition != null;
  double? get latitude => _lastPosition?.latitude;
  double? get longitude => _lastPosition?.longitude;

  String get locationString {
    if (_lastPosition == null) return 'Unknown';
    return '${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}';
  }

  Future<bool> init() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        debugPrint('[Location] Services disabled');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[Location] Permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[Location] Permission permanently denied');
        return false;
      }

      await refreshLocation();
      return true;
    } catch (e) {
      debugPrint('[Location] Init error: $e');
      return false;
    }
  }

  Future<Position?> refreshLocation() async {
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint('[Location] Got: ${_lastPosition!.latitude}, ${_lastPosition!.longitude}');
      return _lastPosition;
    } catch (e) {
      debugPrint('[Location] Refresh error: $e');
      return _lastPosition;
    }
  }

  static String formatCoords(double lat, double lon) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, ${lon.abs().toStringAsFixed(4)}°$lonDir';
  }

  static String toGoogleMapsUrl(double lat, double lon) {
    return 'https://maps.google.com/?q=$lat,$lon';
  }
}
