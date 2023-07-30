import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

class PersistentWebsocket {
  final HttpClient _httpClient = HttpClient();

  WebSocket? _socket;
  Uri? _uri;
  bool _retry = true;
  bool _running = false;

  Function? _onConnect;
  Function? _onDisonnect;

  Future<bool> connect(String socketUrl, {bool retry = true, Function? onConnect, Function? onDisconnect}) async {
    _retry = retry;
    _onConnect = onConnect;
    _onDisonnect = onDisconnect;

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
    _socket = null;

    if(_uri == null) {
      return false;
    }

    try {
      _running = true;
      final key = base64.encode(List<int>.generate(16, (_) => Random().nextInt(256)));
      final request = await _httpClient.getUrl(_uri!);

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
            debugPrint("Disconnect");
        if (_running) {
          _onDisonnect?.call();
          reconnect();
          return;
        }
      });
      debugPrint("Connect");
      _onConnect?.call();
      return true;
    } catch (e) {
      debugPrint("connection failed: ${e.toString()}");
      if (_retry && _running) {
        Future.delayed(const Duration(seconds: 5), () {
          if (_running) {
            reconnect();
            return;
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
      _socket?.add(message);
    } catch (e) {
      debugPrint("Send error: ${e.toString()}");
      _socket = null;
    }
  }
}
