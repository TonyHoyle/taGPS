import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

class PersistentWebsocket {
  WebSocket? _socket;
  late Uri _uri;
  bool _retry = true;
  bool _running = false;

  Future<bool> connect(String socketUrl, {bool retry = true}) async {
    _retry = retry;
    final socketUri = Uri.parse(socketUrl);
    _uri = Uri(
        scheme: socketUri.scheme == 'wss' ? 'https' : 'http',
        userInfo: socketUri.userInfo,
        host: socketUri.host,
        port: socketUri.port,
        path: socketUri.path,
        queryParameters: socketUri.queryParameters,
        fragment: socketUri.fragment
    );
    return reconnect();
  }

  Future<bool> reconnect() async {
    try {
      _socket = null;
      _running = true;
      final key = base64.encode(List<int>.generate(16, (_) => Random().nextInt(256)));
      final client = HttpClient();
      final request = await client.getUrl(_uri);

      // Dart is wierd and lowercases everything by default, which is why we can't
      // use the standard websocket
      request.headers.add('Connection', 'upgrade', preserveHeaderCase: true);
      request.headers.add('Upgrade', 'websocket', preserveHeaderCase: true);
      request.headers.add('Sec-WebSocket-Version', '13', preserveHeaderCase: true);
      request.headers.add('Sec-WebSocket-Key', key, preserveHeaderCase: true);

      HttpClientResponse response = await request.close();
      if (response.statusCode != 101) {
        debugPrint("connection failed: status ${response.statusCode}");
        if (_retry && _running) {
          Future.delayed(const Duration(seconds: 5), () {
            if (_running) {
              reconnect();
            }
          });
        }
        return false;
      }
      Socket socket = await response.detachSocket();

      _socket = WebSocket.fromUpgradedSocket(socket, serverSide: false);

      _socket?.listen((data) { },
          onDone: () {
        if (_running) {
          reconnect();
        }
      });
      return true;
    } catch (e) {
      debugPrint("connection failed: ${e.toString()}");
      if (_retry && _running) {
        Future.delayed(const Duration(seconds: 5), () {
          if (_running) {
            reconnect();
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

  void send(String message) {
    try {
      debugPrint("Sending $message");
      _socket?.add(json);
    } catch (e) {
      debugPrint("Send error: ${e.toString()}");
      _socket = null;
    }
  }
}
