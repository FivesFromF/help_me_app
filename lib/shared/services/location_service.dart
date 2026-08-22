import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isRealGps;
  final String? message;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.isRealGps,
    this.message,
  });

  String get latString => latitude.toStringAsFixed(6);
  String get lonString => longitude.toStringAsFixed(6);
}

class LocationService {
  // Default fallback coordinates (Ho Chi Minh City center)
  static const double defaultLat = 10.762622;
  static const double defaultLon = 106.660172;

  /// Fetch real-time device GPS coordinates with high accuracy
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled on device
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        dev.log('LocationService: GPS service is disabled on device');
        return const LocationResult(
          latitude: defaultLat,
          longitude: defaultLon,
          isRealGps: false,
          message: 'Dịch vụ định vị (GPS) đang tắt trên thiết bị',
        );
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          dev.log('LocationService: Location permission was denied by user');
          return const LocationResult(
            latitude: defaultLat,
            longitude: defaultLon,
            isRealGps: false,
            message: 'Quyền truy cập GPS bị từ chối',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        dev.log('LocationService: Location permission is denied forever');
        return const LocationResult(
          latitude: defaultLat,
          longitude: defaultLon,
          isRealGps: false,
          message: 'Quyền GPS bị khóa trong cài đặt máy',
        );
      }

      // 3. Query physical GPS sensor with 10-second timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      dev.log(
        'LocationService: Real GPS locked -> ${position.latitude}, ${position.longitude} (acc: ${position.accuracy}m)',
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isRealGps: true,
        message: 'Đã nhận tín hiệu GPS vệ tinh',
      );
    } catch (e) {
      dev.log('LocationService error: $e');
      // Graceful fallback on any sensor or timeout error
      return LocationResult(
        latitude: defaultLat,
        longitude: defaultLon,
        isRealGps: false,
        message: 'Không lấy được GPS (${e.toString()})',
      );
    }
  }
}
