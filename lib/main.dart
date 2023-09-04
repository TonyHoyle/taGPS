import 'dart:io';

import 'package:flutter/material.dart';

import 'gpstest.dart';
import 'view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = (Platform.isIOS) ? 'TA' : 'TeslaAndroid';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '$platform GPS Relay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: MyHomePage(title: '$platform GPS Relay'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            actions: [
              PopupMenuButton(
                  itemBuilder: (context) {
                return [
                  const PopupMenuItem<int>(value: 0, child: Text("GPS Test")),
                ];
              }, onSelected: (value) {
                if (value == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                          appBar: AppBar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.inversePrimary,
                              title: Text(widget.title)),
                          body: GpsTest()),
                    ),
                  );
                }
              })
            ]),
        body: GpsView());
  }
}
