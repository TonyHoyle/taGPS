import 'dart:async';
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
  bool _background = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(Duration.zero, () async {
      _prefs = await SharedPreferences.getInstance();
      _background = _prefs.getBool("Background") ?? false;
      await widget.updater.init(_background);
      widget.updater.onUpdate = () => setState(() {});
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
        if(!_background) {
          widget.updater.pause();
        }
        break;
      case AppLifecycleState.resumed:
        if(!_background) {
          widget.updater.resume();
        }
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
          const Text('Connect to the TeslaAndroid hotspot',
              textAlign: TextAlign.center),
          const Text('Ensure browser GPS is disabled',
              textAlign: TextAlign.center),
          const Spacer(),
          Text(widget.updater.connected()
              ? 'Connected to TeslaAndroid'
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
                value: _background,
                onChanged: (value) {
                  _background = value;
                  widget.updater.enableBackgroundMode(context, value);
                  _prefs.setBool("Background", _background);
                  setState(() {});
                })
          ]),
        ]));
  }
}