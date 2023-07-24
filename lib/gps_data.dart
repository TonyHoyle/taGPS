//
// From https://github.com/tesla-android/flutter-app/blob/main/lib/feature/gps/model/gps_data.dart
//
import 'package:json_annotation/json_annotation.dart';
import 'package:location/location.dart';

part 'gps_data.g.dart';

@JsonSerializable()
class GpsData {
  final String latitude;
  final String longitude;
  @JsonKey(name: "vertical_accuracy")
  final String accuracy;
  final String bearing;
  final String speed;
  final String timestamp;

  const GpsData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.bearing,
    required this.speed,
  });

  factory GpsData.fromJson(Map<String, dynamic> json) =>
      _$GpsDataFromJson(json);

  factory GpsData.fromLocationData(LocationData locationData) {
    return GpsData(
      latitude: locationData.latitude.toString(),
      longitude: locationData.longitude.toString(),
      accuracy: locationData.accuracy
          .toString(), // Old code had vertical accuracy here but I'm not sure that makes sense given we're not sending altitude
      timestamp: locationData.time.toString(),
      speed: locationData.speed.toString(),
      bearing: locationData.heading.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$GpsDataToJson(this);
}
