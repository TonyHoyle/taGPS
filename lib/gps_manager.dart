import 'dart:math';

import 'package:flutter/services.dart';
import 'gps_websocket.dart';
import 'package:location/location.dart';

class GpsManager {
  double latitude = 0;
  double longitude = 0;
  double speed = 0;
  double bearing = 0;
  double altitude = 0;
  double calculatedSpeed = 0;
  double calculatedBearing = 0;
  int updateTime = 0;

  Function? onGpsChange;

  final GpsWebsocket _websocket = GpsWebsocket();

  final Location _location = Location();

  Future<bool> connect() async => _websocket.connect();
  bool connected() => _websocket.connected();

  Future<void> init() async {
    bool enabled = false;
    for (int n = 0; n < 100; n++) {
      try {
        enabled = await _location.serviceEnabled();
        break;
      } on PlatformException {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (!enabled) {
      if (!await _location.requestService()) {
        return;
      }
    }

    var status = await _location.hasPermission();
    if (status == PermissionStatus.denied) {
      status = await _location.requestPermission();
    }
    if (status != PermissionStatus.granted) {
      return;
    }

    _location.changeSettings(accuracy: LocationAccuracy.high, interval: 1000, distanceFilter: 0);


    await _websocket.connect();

    _location.onLocationChanged.listen((currentLocation) {
      _updateLocation(currentLocation);
    });
  }

  void stop()
  {
    _websocket.close();
  }

  void start()
  {
    _websocket.connect();
  }

  void _updateLocation(LocationData currentLocation) {

    if (_websocket.connected()) {
      _websocket.send(currentLocation);
    }

    var lastLatitude = latitude;
    var lastLongitude = longitude;
    final lastUpdateTime = updateTime;
    final lastAltitude = altitude;

    latitude = currentLocation.latitude ?? 0;
    longitude = currentLocation.longitude ?? 0;
    speed = currentLocation.speed ?? 0;
    bearing = currentLocation.heading ?? 0;
    altitude = currentLocation.altitude ?? 0;
    updateTime = currentLocation.time?.toInt() ?? 0;

    // Lat and Lon are in degrees, so first go to radians
    final lon1 = _degToRad(longitude);
    final lon2 = _degToRad(lastLongitude);
    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(lastLatitude);

    // I could have just imported a dart library here but that would limit
    // the ability to translate to another language..

    // Bearing
    // At low speeds <1m/s this is probably wrong due to jitter in the GPS signal.
    // Possibly calculate second only if speed is faster
    final diffLon = _degToRad((longitude - lastLongitude));
    final x = cos(lat1) * sin(diffLon);
    final y = cos(lat2) * sin(lat1) - sin(lat2) * cos(lat1) * cos(diffLon);
    final r = atan2(x,y);
    calculatedBearing = _radToDeg(r);

    // Straight line distance
    // There are about a dozen variants of this, all produce slightly
    // different results, some don't even work... this one seems pretty accurate
    const earthRadius = 6378137.0;
    final dLat = sin(lat2 - lat1) / 2;
    final dLon = sin(lon2 - lon1) / 2;
    final flatDistance = 2000 *
        earthRadius *
        asin(sqrt((dLat * dLat) + cos(lat1) * cos(lat2) * (dLon * dLon)));

    // Take into account rise, if available.. this matters on steep hills
    final rise = altitude - lastAltitude;
    var distance = flatDistance;
    if (rise.abs() > 0) {
      distance = sqrt((flatDistance * flatDistance) + (rise * rise));
    }

    calculatedSpeed = distance / (updateTime - lastUpdateTime);

    onGpsChange?.call();
  }

  double _radToDeg(double radians) {
    var deg = radians * 180 / pi;
    return (deg >= 0) ? deg : 360 + deg;
  }

  double _degToRad(double degrees) {
    return degrees * pi / 180;
  }
}
