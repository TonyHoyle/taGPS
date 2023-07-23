
import 'dart:math';

import 'package:location/location.dart';

class GpsData {
  double latitude = 0;
  double longitude = 0;
  double speed = 0;
  double bearing = 0;
  double altitude = 0;
  double calculatedSpeed = 0;
  double calculatedBearing = 0;

  double _updateTime = 0;


  final Location _location = Location();

  Future<void> init() async
  {
    if(!await _location.serviceEnabled()) {
      if (!await _location.requestService()) {
          return;
        }
    }

    var status = await _location.hasPermission();
    if(status == PermissionStatus.denied) {
      status = await _location.requestPermission();
    }
    if(status != PermissionStatus.granted) {
      return;
    }

    _location.onLocationChanged.listen((currentLocation) {
      _updateLocation(currentLocation);
    });
  }

  void _updateLocation(LocationData currentLocation)
  {
    final lastLatitude = latitude;
    final lastLongitude = longitude;
    final lastUpdateTime = _updateTime;
    final lastAltitude = altitude;

    latitude = currentLocation.latitude ?? 0;
    longitude = currentLocation.longitude ?? 0;
    speed = currentLocation.speed ?? 0;
    bearing = currentLocation.heading ?? 0;
    altitude = currentLocation.altitude ?? 0;
    _updateTime = currentLocation.time ?? 0;

    // Lat and Lon are in degrees, so first go to radians
    final lon1 = _degToRad(longitude);
    final lon2 = _degToRad(lastLongitude);
    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(lastLatitude);

    // I could have just imported a dart library here but that would limit
    // the ability to translate to another language..

    // Bearing
    // This is v2 with more complex maths, because the straight distance calc
    // was frequently a couple of degrees out, and that's no good for a GPS.
    //
    // At low speeds <1m/s this is probably wrong due to jitter in the GPS signal.
    // Possibly calculate second only if speed is faster
    final ns = sin(lon2 - lon1) * cos(lat2);
    final ew = cos(lat1) * sin(lat2) -  sin(lat1) * cos(lat2) * cos(lon1 - lon2);
    calculatedBearing = _radToDeg(atan2(ns, ew));

    // Straight line distance
    // There are about a dozen variants of this, all produce slightly
    // different results, some don't even work... this one seems pretty accurate
    const earthRadius = 6378137.0;
    final dLat = sin(lat2 - lat1) / 2;
    final dLon = sin(lon2 - lon1) / 2;
    final flatDistance = 2000 * earthRadius * asin(sqrt((dLat*dLat) + cos(lat1) * cos(lat2) * (dLon*dLon)));

    // Take into account rise, if available.. this matters on steep hills
    final rise = altitude - lastAltitude;
    var distance = flatDistance;
    if(rise.abs() > 0) {
      distance = sqrt((flatDistance * flatDistance) + (rise * rise));
    }

    calculatedSpeed = distance / (_updateTime - lastUpdateTime);
  }

  double _radToDeg(double radians)
  {
    var deg = radians * 180 / pi;
    return (deg >= 0) ? deg : 360+deg;
  }

  double _degToRad(double degrees)
  {
    return degrees * pi / 180;
  }

}