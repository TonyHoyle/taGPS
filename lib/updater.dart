import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../websocket/websocket.dart';
import 'package:location/location.dart';

import 'gps/gps_data.dart';

class Updater {
  static const taGpsSocket = 'wss://device.teslaandroid.com/sockets/gps';

  final PersistentWebsocket _websocket = PersistentWebsocket();
  final Location _location = Location();
  bool _backgroundEnabled = false;
  bool _paused = false;

  Function? onUpdate;

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

    _location.changeSettings(
        accuracy: LocationAccuracy.high, interval: 1000, distanceFilter: 0);

    final platform = (Platform.isIOS) ? 'TA Pi' : 'TeslaAndroid';
    await _location.changeNotificationOptions(
        iconName: "ic_launcher",
        title: "$platform GPS Relay",
        subtitle: "GPS Relay is active",
        onTapBringToFront: false // True is broken
        );

    await _websocket.connect(taGpsSocket, onConnect: () => onUpdate?.call(), onDisconnect: () => onUpdate?.call(), onTimeout: () => die());

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
    _paused = false;
  }

  void die() {
    if(_paused) {
      _websocket.close();
      _backgroundMode(false);
      onUpdate?.call();
    } else {
      _websocket.reconnect(reset: true);
    }
  }

  void enableBackgroundMode(BuildContext context, bool enable) {
    _backgroundEnabled = enable;
    if (!enable) {
      _backgroundMode(false);
    } else {
      Permission.locationAlways.isGranted.then((enabled) => {
            if (enabled)
              {_backgroundMode(true)}
            else
              {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          title: const Text('Permissions needed'),
                          content: const Text(
                              'To continue to send GPS updates when the app is in the background, please set gps permissions to \'Always\''),
                          actions: [
                            TextButton(
                                child: const Text('ok'),
                                onPressed: () async {
                                  await _backgroundMode(true);
                                  _backgroundEnabled = await _location.isBackgroundModeEnabled();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                })
                          ]);
                    })
              }
          });
    }
  }

  Future<bool> _backgroundMode(bool enable) async {
    try {
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
    debugPrint("Got location: ${currentLocation.toString()}");
    if (_websocket.connected()) {
      String json = jsonEncode(GpsData.fromLocationData(currentLocation));
      _websocket.send(json);
    }

    onUpdate?.call();
  }
}
