import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tagps/gps/estimator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../websocket/websocket.dart';
import 'package:location/location.dart';

import 'gps/gps_data.dart';

class Updater {
  static const taGpsSocket = 'wss://device.teslaandroid.com/sockets/gps';

  final PersistentWebsocket _websocket = PersistentWebsocket();
  final Location _location = Location();
  final GpsEstimator _estimator = GpsEstimator();
  bool _backgroundEnabled = false;
  bool _paused = false;
  final _estimate = false;

  Updater._();

  Function? onUpdate;
  Function(LocationData location)? onLocation;

  static final Updater instance = Updater._();

  Future<void> init(bool runInBackground) async {
    bool enabled = false;

    await Permission.locationWhenInUse.request();
    await Permission.notification.request();

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

    await _location.changeSettings(
        accuracy: LocationAccuracy.navigation, interval: 1000, distanceFilter: 0);

    final platform = (Platform.isIOS) ? 'TA Pi device' : 'TeslaAndroid';
    await _location.changeNotificationOptions(
        iconName: "ic_launcher",
        title: "$platform GPS Relay",
        subtitle: "GPS Relay is active",
        onTapBringToFront: false // True is broken
        );

    await _websocket.connect(taGpsSocket,
        onConnect: () => onUpdate?.call(),
        onDisconnect: () => onUpdate?.call(),
        onTimeout: () => die());

    _location.onLocationChanged.listen((currentLocation) {
      _updateLocation(currentLocation);
    });

    _backgroundEnabled = runInBackground;
    _backgroundMode(runInBackground);
  }

  void pause() {
    if (!_backgroundEnabled) {
      _websocket.close();
    }
    _paused = true;
  }

  void resume() {
    _websocket.reconnect();
    _backgroundMode(_backgroundEnabled);
    _paused = false;
  }

  void die() {
    if (_paused) {
      _websocket.close();
      _backgroundMode(false);
      onUpdate?.call();
    } else {
      _websocket.reconnect(reset: true);
    }
  }

  Future enableBackgroundMode(BuildContext context, bool enable) async {
    _backgroundEnabled = enable;
    if (!enable) {
      await _backgroundMode(false);
    } else {
      if (Platform.isIOS) {
        // ignore: use_build_context_synchronously
        if(!context.mounted) { return; }
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: const Text('Background mode'),
                  content: const Text(
                      'In background mode the app will continue to relay GPS data in the background.  If it loses connection to TA for more than 2 minutes it will stop.'),
                  actions: [
                    TextButton(
                        child: const Text('ok'),
                        onPressed: () async {
                          await _backgroundMode(true);
                          _backgroundEnabled =
                          await _location.isBackgroundModeEnabled();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        })
                  ]);
            });
      } else if (Platform.isAndroid) {
        if (await Permission.locationAlways.isGranted) {
          await _backgroundMode(true);
        } else {
          // ignore: use_build_context_synchronously
          if(!context.mounted) { return; }
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: const Text('Permissions needed'),
                    content: const Text(
                        'To continue to send GPS updates when the app is in the background, please set gps permissions to \'Allow all the time\'.\n\nThe app will stop attempting to send background updates if it loses connection to TeslaAndroid for more than 2 minutes.'),
                    actions: [
                      TextButton(
                          child: const Text('ok'),
                          onPressed: () async {
                            await _backgroundMode(true);
                            _backgroundEnabled =
                                await _location.isBackgroundModeEnabled();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          })
                    ]);
              });
        }
      }
    }
  }

  Future<bool> _backgroundMode(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: !enable);
      return await _location.enableBackgroundMode(enable: enable);
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  void enable(bool enable) {
    if (enable) {
      _websocket.reconnect();
      _backgroundMode(_backgroundEnabled);
    } else {
      _websocket.close();
      _backgroundMode(false);
    }
  }

  bool connected() {
    return _websocket.connected();
  }

  bool backgroundEnabled() {
    return _backgroundEnabled;
  }

  void _updateLocation(LocationData currentLocation) {
    debugPrint("Got location: ${jsonEncode(GpsData.fromLocationData(currentLocation))}");
    if(_estimate || (currentLocation?.speed ?? -1) < 0) {
      currentLocation = _estimator.estimate(currentLocation);
      debugPrint("Estimate location: ${jsonEncode(GpsData.fromLocationData(currentLocation))}");
    }
    if (_websocket.connected()) {
      String json = jsonEncode(GpsData.fromLocationData(currentLocation));
      _websocket.send(json);
    }

    onLocation?.call(currentLocation);
    onUpdate?.call();
  }
}
