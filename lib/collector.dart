import 'package:flutter/material.dart';
// import 'package:map/main.dart';
import 'dart:async';
// import 'dart:collection';
import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:map/collector.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:csv/csv.dart';

class CollectorPage extends StatefulWidget {
  const CollectorPage({super.key, required this.title});

  final String title;

  @override
  State<CollectorPage> createState() => _CollectorPageState();
}

class _CollectorPageState extends State<CollectorPage> {
  AccelerometerEvent? accelerometerEvent;
  UserAccelerometerEvent? userAccelerometerEvent;
  GyroscopeEvent? gyroscopeEvent;
  bool recording = false;
  bool pothole = false;
  bool good_road = true;

  static List<String> csvHeader = [
    'Timestamp',
    'accelerometer_x',
    'accelerometer_y',
    'accelerometer_z',
    'user_accelerometer_x',
    'user_accelerometer_y',
    'user_accelerometer_z',
    'gyroscope_x',
    'gyroscope_y',
    'gyroscope_z',
    'pothole',
    'good_road'
  ];
  List<List<dynamic>> csvData = [csvHeader];
  // DoubleLinkedQueue<List<double>> csvData = DoubleLinkedQueue();
  // Interpreter? interpreter;

  // void loadModel() async {
  //   interpreter = await Interpreter.fromAsset('assets/model.tflite');
  // }

  @override
  void initState() {
    super.initState();
    // loadModel();
    accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((AccelerometerEvent event) {
      setState(() {
        accelerometerEvent = event;
      });
    });
    userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((UserAccelerometerEvent event) {
      setState(() {
        userAccelerometerEvent = event;
      });
    });
    gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((GyroscopeEvent event) {
      setState(() {
        gyroscopeEvent = event;
      });
    });

    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (recording) {
        csvData.add([
          DateTime.now().millisecondsSinceEpoch,
          accelerometerEvent!.x,
          accelerometerEvent!.y,
          accelerometerEvent!.z,
          userAccelerometerEvent!.x,
          userAccelerometerEvent!.y,
          userAccelerometerEvent!.z,
          gyroscopeEvent!.x,
          gyroscopeEvent!.y,
          gyroscopeEvent!.z,
          pothole,
          good_road
        ]);
        // if (csvData.length > 100) {
        //   csvData.removeFirst();
        // }
      }

      // Timer.periodic(const Duration(seconds: 2), (timer) {
      //   if (csvData.length < 100) {
      //     return;
      //   }
      //   var input = csvData.toList().reshape([1, 100, 6, 1]);
      //   var output = List.filled(1, 2).reshape([1, 1]);
      //   interpreter!.run(input, output);
      //   setState(() {
      //     pothole = output[0][0] > 0.1;
      //     confidence = output[0][0];
      //   });
      // });
    });
  }

  Future<String> saveDataToCsv() async {
    if (Platform.isAndroid &&
        !await Permission.manageExternalStorage.request().isGranted) {
      return "File Permission denied";
    }
    String csvData = const ListToCsvConverter().convert(this.csvData.toList());
    final Directory directory = Platform.isAndroid
        ? await getExternalStorageDirectory().then((value) => value!)
        : await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/sensor_${DateTime.now()}.csv';
    await File(path).writeAsString(csvData);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (recording) {
                      recording = false;
                      saveDataToCsv().then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Data saved to $value')));
                      });
                    } else {
                      recording = true;
                      // csvData = [csvHeader];
                    }
                    csvData.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: recording ? Colors.green : Colors.red),
                child: Text(!recording ? 'RECORD' : 'STOP',
                    style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 5.0,
                        fontWeight: FontWeight.w900,
                        fontSize: 20.0))),
          ),
          const Spacer(flex: 50),
          Text(
            'Raw Accelerometer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(flex: 20),
          Text(
            'x: ${accelerometerEvent?.x.toStringAsFixed(3)} \n y: ${accelerometerEvent?.y.toStringAsFixed(3)} \n z: ${accelerometerEvent?.z.toStringAsFixed(3)}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Spacer(flex: 50),
          Text(
            'Processed Accelerometer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(flex: 20),
          Text(
            'x: ${userAccelerometerEvent?.x.toStringAsFixed(3)} \n y: ${userAccelerometerEvent?.y.toStringAsFixed(3)} \n z: ${userAccelerometerEvent?.z.toStringAsFixed(3)}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Spacer(flex: 50),
          Text(
            'Gyroscope',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(flex: 20),
          Text(
            'x: ${gyroscopeEvent?.x.toStringAsFixed(3)} \n y: ${gyroscopeEvent?.y.toStringAsFixed(3)} \n z: ${gyroscopeEvent?.z.toStringAsFixed(3)}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Spacer(flex: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        good_road = !good_road;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                            color: good_road
                                ? Colors.green
                                : Colors.yellow.shade800,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(good_road ? 'GOOD ROAD' : 'BAD ROAD',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 5.0,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20.0)),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        if (!recording) {
                          recording = true;
                          csvData = [csvHeader];
                          // csvData.clear();
                        }
                        pothole = true;
                      });
                    },
                    onTapUp: (details) {
                      setState(() {
                        pothole = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                              color: pothole
                                  ? Colors.green
                                  : Colors.yellow.shade800,
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Text(
                                !pothole ? 'MARK POTHOLE' : 'MARKING...',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    letterSpacing: 5.0,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20.0)),
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 50),
        ],
      ),
    );
  }
}
