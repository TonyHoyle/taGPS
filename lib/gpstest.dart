import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';

import 'gps/estimator.dart';
import 'updater.dart';

class GpsTest extends StatefulWidget {
  GpsTest({super.key});

  final Updater updater = Updater.instance;
  final GpsEstimator estimator = GpsEstimator();

  @override
  State<GpsTest> createState() => _GpsTestState();
}

class _GpsTestState extends State<GpsTest> with WidgetsBindingObserver {
  // ignore: constant_identifier_names
  static const Mph = 2.23694;
//  static const Kph = 3.6;

  final _speedConstant = Mph;
  final _speedSuffix = 'mph';

  LocationData? _realLocation;
  LocationData? _fakeLocation;

  @override
  void initState() {
    widget.updater.onLocation = onLocation;
    super.initState();
  }

  @override
  void dispose() {
    widget.updater.onLocation = null;
    super.dispose();
  }

  void onLocation(LocationData location)
  {
    _realLocation = location;
    _fakeLocation = widget.estimator.estimate(location);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          SizedBox(
              width: 270,
              height: 300,
              child: Row(children: [
                Center(
                    child: Column(children: [
                      const Text('Latitude'),
                      Text(NumberFormat("##0.0##").format(_realLocation?.latitude),
                          style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      const Text('Speed (actual)'),
                      Text(
                          "${NumberFormat("###0").format((_realLocation?.speed ?? 0) * _speedConstant)}$_speedSuffix",
                          style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      const Text('Bearing (actual)'),
                      Text(
                          "${NumberFormat("###0").format(_realLocation?.heading)}°",
                          style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      const Text('Update time'),
                      Text(
                          DateFormat.Hms().format(DateTime.fromMillisecondsSinceEpoch(_realLocation?.time?.toInt() ?? 0)),
                          style: const TextStyle(fontSize: 28))
                    ])),
                const Spacer(),
                Center(
                    child: Column(children: [
                      const Text('Longitude'),
                      Text(NumberFormat("##0.0##").format(_realLocation?.longitude),
                          style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      const Text('Speed (calculated))'),
                      Text(
                          "${NumberFormat("###0").format((_fakeLocation?.speed ?? 0) * _speedConstant)}$_speedSuffix",
                          style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      const Text('Bearing (calculated)'),
                      Text(
                          "${NumberFormat("###0").format(_fakeLocation?.heading)}°",
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 80),
                    ])),
              ])),
        ]));
  }
}