import 'dart:convert';

import 'package:location/location.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'gps_data.dart';

class GpsWebsocket {
  static const taGpsSocket = 'ws://device.teslaandroid.com/sockets/gps';

  WebSocketChannel? _channel;

  Future<bool> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(taGpsSocket));
      await _channel?.ready;
      return true;
    } catch(e) {
      _channel = null;
      return false;
    }
  }

  bool connected() {
    return _channel != null;
  }

  void close() {
    _channel?.sink.close();
    _channel = null;
  }

  void send(LocationData location) {
    String json = jsonEncode(GpsData.fromLocationData(location));

    try {
      _channel?.sink.add(json);
    }
    catch(e) {
      _channel = null;
    }
  }
}
