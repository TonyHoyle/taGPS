import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'updater.dart';

class GpsView extends StatefulWidget {
  GpsView({super.key});

  final Updater updater = Updater();

  @override
  State<GpsView> createState() => _GpsViewState();
}

class _GpsViewState extends State<GpsView> with WidgetsBindingObserver {
  bool _enabled = true;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(Duration.zero, () async {
      _prefs = await SharedPreferences.getInstance();
      await widget.updater.init(_prefs.getBool("Background") ?? false);
      widget.updater.onUpdate = () => setState(() {});
      setState((){});
    });
  }

  @override
  void dispose() {
    widget.updater.enable(false);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state)
    {
      case AppLifecycleState.paused:
        widget.updater.pause();
        break;
      case AppLifecycleState.resumed:
        widget.updater.resume();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = (Platform.isIOS) ? 'TA Pi' : 'TeslaAndroid';
    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text('Connect phone to the $platform hotspot',
              textAlign: TextAlign.center),
          const Text('Ensure browser GPS is disabled',
              textAlign: TextAlign.center),
          const Spacer(),
          Text(widget.updater.connected()
              ? 'Connected to $platform'
              : 'Trying to connect'),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Enabled'),
            Switch(
                value: _enabled,
                onChanged: (value) {
                  _enabled = value;
                  widget.updater.enable(_enabled);
                  setState(() {});
                })
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Run in Background'),
            Switch(
                value: widget.updater.backgroundEnabled(),
                onChanged: (value) {
                  widget.updater.enableBackgroundMode(context, value);
                  _prefs.setBool("Background", widget.updater.backgroundEnabled());
                  setState(() {});
                })
          ]),
        ]));
  }
}
