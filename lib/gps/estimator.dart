import 'dart:math';

import 'package:location/location.dart';

class GpsEstimator {
  double _lastLatitude = 0;
  double _lastLongitude = 0;
  double _lastAltitude = 0;
  double _lastHeading = 0;
  int _lastTime = 0;

  LocationData estimate(LocationData source) {
    final latitude = source.latitude ?? 0;
    final longitude = source.longitude ?? 0;
    final altitude = source.altitude ?? 0;
    final updateTime = source.time?.toInt() ?? 0;

    // Lat and Lon are in degrees, so first go to radians
    final lon1 = _degToRad(longitude);
    final lon2 = _degToRad(_lastLongitude);
    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(_lastLatitude);

    // I could have just imported a dart library here but that would limit
    // the ability to translate to another language..

    // Bearing
    // At low speeds <1m/s this is probably wrong due to jitter in the GPS signal.
    // Possibly calculate second only if speed is faster
    final diffLon = _degToRad((longitude - _lastLongitude));
    final x = cos(lat1) * sin(diffLon);
    final y = cos(lat2) * sin(lat1) - sin(lat2) * cos(lat1) * cos(diffLon);
    final r = atan2(x,y);
    final heading = _radToDeg(r);

    // Straight line distance
    // There are about a dozen variants of this, all produce slightly
    // different results, some don't even work... this one seems pretty accurate
    const earthRadius = 6378137.0;
    final dLat = sin(lat2 - lat1) / 2;
    final dLon = sin(lon2 - lon1) / 2;
    var flatDistance = 2000 *
        earthRadius *
        asin(sqrt((dLat * dLat) + cos(lat1) * cos(lat2) * (dLon * dLon)));

    // Take into account rise, if available.. this matters on steep hills
//    final rise = altitude - _lastAltitude;
//    if (rise.abs() > 0) {
//      flatDistance = sqrt((flatDistance * flatDistance) + (rise * rise));
//    }

    // Compensate for heading changes
    final theta = _degToRad(_lastHeading - heading);
    final distance = flatDistance / cos(theta);

    final speed = distance / (updateTime - _lastTime);

    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _lastTime = updateTime;
    _lastAltitude = altitude;
    _lastHeading = heading;

    return LocationData.fromMap({
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': source.accuracy,
            'altitude': altitude,
            'speed' : speed,
            'speedAccuracy' : 0.0,
            'heading': heading,
            'time': source.time,
            'isMock': source.isMock,
            'verticalAccuracy': source.verticalAccuracy,
            'headingAccuracy': 0.0,
            'elapsedRealtimeNanos': source.elapsedRealtimeNanos,
            'elapsedRealtimeUncertaintyNanos': source.elapsedRealtimeUncertaintyNanos,
            'satelliteNumber': source.satelliteNumber,
            'provider': source.provider});
  }

  double _radToDeg(double radians) {
    var deg = radians * 180 / pi;
    return (deg >= 0) ? deg : 360 + deg;
  }

  double _degToRad(double degrees) {
    return degrees * pi / 180;
  }
}
