import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wakelock/wakelock.dart';

import 'gps_manager.dart';

class GpsView extends StatefulWidget {
  GpsView({super.key});

  final GpsManager gpsManager = GpsManager();

  @override
  State<GpsView> createState() => _GpsViewState();
}

class _GpsViewState extends State<GpsView> with WidgetsBindingObserver {
  // ignore: constant_identifier_names
  static const Mph = 2.23694;
//  static const Kph = 3.6;

  final _speedConstant = Mph;
  final _speedSuffix = 'mph';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () async {
      await widget.gpsManager.init();
      start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();

    super.dispose();
  }

  void start() {
    Wakelock.enable();
    widget.gpsManager.onGpsChange = () => setState(() { });
    widget.gpsManager.start();
  }

  void stop() {
    Wakelock.disable();
    widget.gpsManager.stop();
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
        child: Column(children: [
          SizedBox(
              width: 270,
              height: 300,
              child: Row(children: [
                Center(
                    child: Column(children: [
                  const Text('Latitude'),
                  Text(NumberFormat("##0.0##").format(widget.gpsManager.latitude),
                      style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  const Text('Speed (actual)'),
                  Text(
                      "${NumberFormat("###0").format(widget.gpsManager.speed * _speedConstant)}$_speedSuffix",
                      style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  const Text('Bearing (actual)'),
                  Text(
                      "${NumberFormat("###0").format(widget.gpsManager.bearing)}°",
                      style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  const Text('Update time'),
                  Text(
                      DateFormat.Hms().format(DateTime.fromMillisecondsSinceEpoch(widget.gpsManager.updateTime.toInt())),
                      style: const TextStyle(fontSize: 28))
                ])),
                const Spacer(),
                Center(
                    child: Column(children: [
                  const Text('Longitude'),
                  Text(NumberFormat("##0.0##").format(widget.gpsManager.longitude),
                      style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  const Text('Speed (calculated))'),
                  Text(
                      "${NumberFormat("###0").format(widget.gpsManager.calculatedSpeed * _speedConstant)}$_speedSuffix",
                      style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  const Text('Bearing (calculated)'),
                  Text(
                      "${NumberFormat("###0").format(widget.gpsManager.calculatedBearing)}°",
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 80),
                ])),
              ])),
          Row(children: [
            TextButton(
                onPressed: widget.gpsManager.connected()
                    ? null
                    : () async {
                        await widget.gpsManager.connect();
                        setState(() {});
                      },
                child: Text(widget.gpsManager.connected() ? 'Connected' : 'Connect to TeslaAndroid'))
          ])
        ]));
  }
}
