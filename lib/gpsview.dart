import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wakelock/wakelock.dart';

import 'gps.dart';

class GpsView extends StatefulWidget {
  GpsView({super.key});

  final GpsData gpsData = GpsData();

  @override
  State<GpsView> createState() => _GpsViewState();
}

class _GpsViewState extends State<GpsView> with WidgetsBindingObserver {
  // ignore: constant_identifier_names
  static const Mph = 2.23694;
//  static const Kph = 3.6;

  Timer? _timer;
  final _speedConstant = Mph;
  final _speedSuffix = 'mph';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () async {
      await widget.gpsData.init();
      start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();

    super.dispose();
  }

  void start()
  {
    Wakelock.enable();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      setState(() {});
    });
  }

  void stop()
  {
    _timer?.cancel();
    Wakelock.disable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // These are the callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        start();
        break;
      case AppLifecycleState.paused:
        stop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
            width: 270,
            height: 200,
            child: Row(children: [
              Center(
                  child: Column(children: [
                const Text('Latitude'),
                Text(NumberFormat("##0.0##").format(widget.gpsData.latitude),
                    style: const TextStyle(fontSize: 28)),
                const Spacer(),
                const Text('Speed (actual)'),
                Text("${NumberFormat("###0").format(widget.gpsData.speed * _speedConstant)}$_speedSuffix",
                    style: const TextStyle(fontSize: 28)),
                const Spacer(),
                const Text('Bearing (actual)'),
                Text("${NumberFormat("###0").format(widget.gpsData.bearing)}°",
                    style: const TextStyle(fontSize: 28)),
              ])),
              const Spacer(),
              Center(
                  child: Column(children: [
                const Text('Longitude'),
                Text(NumberFormat("##0.0##").format(widget.gpsData.longitude),
                    style: const TextStyle(fontSize: 28)),
                const Spacer(),
                const Text('Speed (calculated))'),
                Text(
                    "${NumberFormat("###0").format(widget.gpsData.calculatedSpeed * _speedConstant)}$_speedSuffix",
                    style: const TextStyle(fontSize: 28)),
                const Spacer(),
                const Text('Bearing (calculated)'),
                Text(
                    "${NumberFormat("###0").format(widget.gpsData.calculatedBearing)}°",
                    style: const TextStyle(fontSize: 28))
              ])),
            ])));
  }
}
