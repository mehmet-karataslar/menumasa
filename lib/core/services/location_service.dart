import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  StreamSubscription<Position>? _positionStream;
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastKnownPosition => _lastKnownPosition;

  // =============================================================================
  // PERMISSIONS
  // =============================================================================

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Request all necessary location permissions
  Future<bool> requestLocationPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return false;
    }

    // Check permissions
    LocationPermission permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  // =============================================================================
  // LOCATION TRACKING
  // =============================================================================

  /// Get current position
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      if (!await requestLocationPermissions()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Start location tracking
  Future<bool> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    Duration interval = const Duration(seconds: 30),
  }) async {
    try {
      if (!await requestLocationPermissions()) {
        return false;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _positionController.add(position);
          print('Location updated: ${position.latitude}, ${position.longitude}');
        },
        onError: (error) {
          print('Location tracking error: $error');
        },
      );

      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    print('Location tracking stopped');
  }

  /// Check if location tracking is active
  bool get isTrackingLocation => _positionStream != null;

  // =============================================================================
  // DISTANCE & GEOCODING
  // =============================================================================

  /// Calculate distance between two points in meters
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate distance from current position to a point
  double? calculateDistanceFromCurrent(double latitude, double longitude) {
    if (_lastKnownPosition == null) return null;
    
    return calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      latitude,
      longitude,
    );
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
    }
    return null;
  }

  /// Get coordinates from address
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      print('Error getting coordinates from address: $e');
    }
    return null;
  }

  // =============================================================================
  // BUSINESS LOCATION UTILITIES
  // =============================================================================

  /// Find nearby businesses based on current location
  List<Map<String, dynamic>> filterNearbyBusinesses(
    List<Map<String, dynamic>> businesses,
    double radiusInKm,
  ) {
    if (_lastKnownPosition == null) return businesses;

    return businesses.where((business) {
      final businessLat = business['latitude'] as double?;
      final businessLon = business['longitude'] as double?;
      
      if (businessLat == null || businessLon == null) return false;

      final distance = calculateDistance(
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
        businessLat,
        businessLon,
      );

      return distance <= (radiusInKm * 1000); // Convert km to meters
    }).toList();
  }

  /// Sort businesses by distance from current location
  List<Map<String, dynamic>> sortBusinessesByDistance(
    List<Map<String, dynamic>> businesses,
  ) {
    if (_lastKnownPosition == null) return businesses;

    businesses.sort((a, b) {
      final distanceA = calculateDistance(
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
        a['latitude'] as double? ?? 0,
        a['longitude'] as double? ?? 0,
      );
      
      final distanceB = calculateDistance(
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
        b['latitude'] as double? ?? 0,
        b['longitude'] as double? ?? 0,
      );

      return distanceA.compareTo(distanceB);
    });

    return businesses;
  }

  /// Get formatted distance string
  String getFormattedDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Check if user is within delivery radius of a business
  bool isWithinDeliveryRadius(
    double businessLat,
    double businessLon,
    double deliveryRadiusKm,
  ) {
    if (_lastKnownPosition == null) return false;

    final distance = calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      businessLat,
      businessLon,
    );

    return distance <= (deliveryRadiusKm * 1000);
  }

  // =============================================================================
  // CLEANUP
  // =============================================================================

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
    _positionController.close();
  }
} 