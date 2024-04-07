import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:map/collector.dart';
import 'package:map/env.dart';
import 'package:map/mapplmap.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapplsAccountManager.setMapSDKKey(MAP_SDK_KEY);
  MapplsAccountManager.setRestAPIKey(REST_API_KEY);
  MapplsAccountManager.setAtlasClientId(ATLAS_CLIENT_ID);
  MapplsAccountManager.setAtlasClientSecret(ATLAS_CLIENT_SECRET);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pothole Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int onPage = 0;
  final titles = ['Pothole Map', 'Pothole Detection'];

  void requestLocation() async {
    if (!await Permission.location.request().isGranted) {
      print("Location Permission denied");
    }
  }

  Timer? timer;
  DoubleLinkedQueue<List<double>> csvData = DoubleLinkedQueue();

  @override
  void initState() {
    requestLocation();
    // timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
    //   if (userAccelerometerEvent == null || gyroscopeEvent == null) {
    //     return;
    //   }
    //   csvData.add([
    //     DateTime.now().millisecondsSinceEpoch.toDouble(),
    //     userAccelerometerEvent!.x,
    //     userAccelerometerEvent!.y,
    //     userAccelerometerEvent!.z,
    //     gyroscopeEvent!.x,
    //     gyroscopeEvent!.y,
    //     gyroscopeEvent!.z,
    //   ]);
    //   if (csvData.length > 100) {
    //     csvData.removeFirst();
    //   }
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(titles[onPage]),
        centerTitle: true,
      ),
      body: onPage == 0 ? MapWidget() : CollectorPage(title: 'Data Collector'),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Pothole Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_exploration_outlined),
            label: 'Data Collector',
          ),
        ],
        currentIndex: onPage,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          setState(() {
            onPage = index;
          });
        },
      ),
    );
  }
}
