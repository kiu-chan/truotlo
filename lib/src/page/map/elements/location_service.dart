import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<bool> checkAndRequestLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDisabledDialog(context);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog(context);
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showPermissionPermanentlyDeniedDialog(context);
      return false;
    }

    return true;
  }

  void startLocationUpdates(Function(LatLng) onLocationUpdate, Function(dynamic) onError) {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen(
      (Position position) {
        onLocationUpdate(LatLng(position.latitude, position.longitude));
      },
      onError: onError
    );
  }

  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
  }

  void _showLocationServiceDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Dịch vụ vị trí bị tắt'),
        content: const Text('Vui lòng bật dịch vụ vị trí để sử dụng tính năng này.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Mở cài đặt'),
            onPressed: () => Geolocator.openLocationSettings(),
          ),
          TextButton(
            child: const Text('Đóng'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối. Một số tính năng có thể không hoạt động.')),
    );
  }

  void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cần quyền truy cập vị trí'),
        content: const Text('Ứng dụng cần quyền truy cập vị trí để hiển thị vị trí của bạn trên bản đồ. Vui lòng cấp quyền trong cài đặt ứng dụng.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Mở cài đặt'),
            onPressed: () => Geolocator.openAppSettings(),
          ),
          TextButton(
            child: const Text('Đóng'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}