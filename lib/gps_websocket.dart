import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:location/location.dart';

import 'gps_data.dart';

class GpsWebsocket {
  static const taGpsSocket = 'https://device.teslaandroid.com/sockets/gps';

  WebSocket? _socket;

  Future<bool> connect() async {
    try {
      final key = base64.encode(List<int>.generate(16, (_) => Random().nextInt(256)));
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(taGpsSocket));

      request.headers.add('Connection', 'upgrade', preserveHeaderCase: true);
      request.headers.add('Upgrade', 'websocket', preserveHeaderCase: true);
      request.headers.add('Sec-WebSocket-Version', '13', preserveHeaderCase: true); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key, preserveHeaderCase: true);

      HttpClientResponse response = await request.close();
      if(response.statusCode != 101) {
        _socket = null;
        return false;
      }
      Socket socket = await response.detachSocket();

      _socket = WebSocket.fromUpgradedSocket(socket, serverSide: false);
      return true;
    } catch(e) {
      _socket = null;
      return false;
    }
  }

  bool connected() {
    return _socket != null;
  }

  void close() {
    _socket?.close();
    _socket = null;
  }

  void send(LocationData location) {
    String json = jsonEncode(GpsData.fromLocationData(location));

    try {
      _socket?.add(json);
    }
    catch(e) {
      _socket = null;
    }
  }
}
