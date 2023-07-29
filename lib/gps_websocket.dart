import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

import 'gps_data.dart';

class GpsWebsocket {
  static const taGpsSocket = 'https://device.teslaandroid.com/sockets/gps';

  WebSocket? _socket;
  bool _running = false;

  Future<bool> connect({bool retry = true}) async {
    try {
      debugPrint("Connecting");
      _running = true;
      final key =
          base64.encode(List<int>.generate(16, (_) => Random().nextInt(256)));
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(taGpsSocket));

      request.headers.add('Connection', 'upgrade', preserveHeaderCase: true);
      request.headers.add('Upgrade', 'websocket', preserveHeaderCase: true);
      request.headers.add('Sec-WebSocket-Version', '13',
          preserveHeaderCase: true); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key, preserveHeaderCase: true);

      HttpClientResponse response = await request.close();
      if (response.statusCode != 101) {
        debugPrint("connection failed: status ${response.statusCode}");
        _socket = null;
        if (retry) {
          Future.delayed(const Duration(seconds: 5), () {
            if (_running) {
              connect();
            }
          });
        }
        return false;
      }
      Socket socket = await response.detachSocket();

      _socket = WebSocket.fromUpgradedSocket(socket, serverSide: false);

      _socket?.listen((data) {
        debugPrint("data");
      }, onDone: () {
        debugPrint("Done");
        _socket = null;
        if (_running) {
          connect();
        }
      }, onError: (error) {
        debugPrint("Error");
      });
      debugPrint("Connected");
      return true;
    } catch (e) {
      debugPrint("connection failed: ${e.toString()}");
      _socket = null;
      if (retry) {
        Future.delayed(const Duration(seconds: 5), () {
          if (_running) {
            connect();
          }
        });
      }
      return false;
    }
  }

  bool connected() {
    return _socket != null;
  }

  void close() {
    _running = false;
    _socket?.close();
    _socket = null;
  }

  void send(LocationData location) {
    String json = jsonEncode(GpsData.fromLocationData(location));

    try {
      debugPrint("Sending $json");
      _socket?.add(json);
    } catch (e) {
      debugPrint("Send error: ${e.toString()}");
      _socket = null;
    }
  }
}
