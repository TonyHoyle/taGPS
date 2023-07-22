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

class _GpsViewState extends State<GpsView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    Future.delayed(const Duration(seconds: 1), () async {
      await widget.gpsData.init();
      _timer = Timer.periodic(const Duration(milliseconds: 250), (t) async {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    Wakelock.disable();
    super.dispose();
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
                Text("${NumberFormat("###0").format(widget.gpsData.speed * 2.23694)}mph",
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
                    "${NumberFormat("###0").format(widget.gpsData.calculatedSpeed * 2.23694)}mph",
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
