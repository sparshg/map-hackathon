import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:map/env.dart';
import 'package:map/place.dart';
import 'package:http/http.dart' as http;
import 'package:map/utils.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({
    super.key,
  });
  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  MapplsMapController? controller;
  LatLng? source, destination;
  UserLocation? current;
  bool loaded = false, requestLoc = false, navigating = false;
  MyLocationRenderMode myLocationRenderMode = MyLocationRenderMode.COMPASS;
  Timer? timer, timer2;
  DoubleLinkedQueue<List<double>> csvData = DoubleLinkedQueue();
  UserAccelerometerEvent? userAccelerometerEvent;
  GyroscopeEvent? gyroscopeEvent;
  List<LatLng>? route;

  @override
  void initState() {
    userAccelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 20))
        .listen((UserAccelerometerEvent event) {
      userAccelerometerEvent = event;
    });
    gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: 20))
        .listen((GyroscopeEvent event) {
      gyroscopeEvent = event;
    });
    super.initState();
  }

  void addListTimer(timer) {
    if (userAccelerometerEvent == null ||
        gyroscopeEvent == null ||
        current == null ||
        !navigating) {
      return;
    }
    csvData.add([
      current!.position.latitude,
      current!.position.longitude,
      userAccelerometerEvent!.x,
      userAccelerometerEvent!.y,
      userAccelerometerEvent!.z,
      gyroscopeEvent!.x,
      gyroscopeEvent!.y,
      gyroscopeEvent!.z,
    ]);
    if (csvData.length > 100) {
      csvData.removeFirst();
    }
  }

  void apiTimer(timer) {
    if (csvData.length == 100) {
      final body = const ListToCsvConverter().convert(csvData.toList());
      // print("OKa");
      http.post(Uri.parse('$BASE_URL/potholes'), body: body);
      // .then((value) => print("OKAAAAAA ${value.body}"));
    }
  }

  void getPotholePath() {
    if (route == null) return;
    http
        .post(Uri.parse('$BASE_URL/getPotholes'),
            body: const ListToCsvConverter()
                .convert(route!.map((e) => [e.latitude, e.longitude]).toList()))
        .then((value) {
      List<dynamic> data = jsonDecode(value.body)["Points"] ?? [];
      if (data.isEmpty) return;
      List<List<double>> coords = [];
      for (var m in data) {
        controller?.addCircle(CircleOptions(
          geometry: LatLng(m["Latitude"], m["Longitude"]),
          circleRadius: 5.0,
          circleColor: '#FF0000',
        ));
        coords.add([m["Latitude"], m["Longitude"]]);
      }
      // gradientPolyLine(controller, coords);
      // setState(() {
      // nextPothole = LatLng(coords[0][0], coords[0][1]);
      // });

      http
          .get(Uri.parse(
              'https://apis.mappls.com/advancedmaps/v1/${REST_API_KEY}/rev_geocode/?lat=${coords[0][0]}&lng=${coords[0][1]}'))
          .then((value) {
        final data = jsonDecode(value.body)["results"][0]["street"];
        showSnackBar(context, "Pothole on $data");
      });
      // final data =
      //     jsonDecode(snapshot.data!.body)["results"][0]["street"];
      // showSnackBar(context, "Pothole on ")
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      controller?.clearSymbols();
      if (source != null) {
        controller?.addSymbol(SymbolOptions(
          geometry: source!,
          iconImage: 'assets/custom-icon.png',
          // iconColor: '#3bb2d0',
        ));
      }
      if (destination != null) {
        controller?.addSymbol(SymbolOptions(
          geometry: destination!,
          iconImage: 'assets/custom-icon.png',
        ));
      }
      if (source != null && destination != null && requestLoc) {
        requestLoc = false;
        getDirection(source!, destination!).then((value) {
          controller?.clearLines();
          route = value;
          if (value != null) {
            drawPath(value, controller);
            controller?.clearCircles();
            getPotholePath();
          }
        });
      }
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: TextButton(
                    onPressed: () {
                      openMapplsPicker().then((value) => {
                            if (value.latitude != null &&
                                value.longitude != null)
                              setState(() {
                                source =
                                    LatLng(value.latitude!, value.longitude!);
                                requestLoc = true;
                              })
                          });
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 16)),
                      backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.primaryContainer),
                      foregroundColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.onBackground),
                    ),
                    child: const Text("Select Source")),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: TextButton(
                    onPressed: () {
                      openMapplsPicker().then((value) => {
                            if (value.latitude != null &&
                                value.longitude != null)
                              setState(() {
                                destination =
                                    LatLng(value.latitude!, value.longitude!);
                                requestLoc = true;
                              })
                          });
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 16)),
                      backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.primaryContainer),
                      foregroundColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.onBackground),
                    ),
                    child: const Text("Select Destination")),
              ),
            ),
            // Expanded(
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: IconButton(
                icon: !navigating
                    ? const Icon(Icons.directions_rounded)
                    : const Icon(Icons.directions_off_rounded),
                onPressed: () {
                  setState(() {
                    timer?.cancel();
                    timer2?.cancel();
                    if (current != null) {
                      if (!navigating) {
                        myLocationRenderMode = MyLocationRenderMode.GPS;
                        controller?.animateCamera(
                            CameraUpdate.newCameraPosition(CameraPosition(
                                target: current!.position,
                                zoom: 17.5,
                                tilt: 45.0,
                                bearing:
                                    current!.heading?.trueHeading ?? 0.0)));
                        timer = Timer.periodic(
                            const Duration(milliseconds: 20), addListTimer);
                        timer2 = Timer.periodic(
                            const Duration(seconds: 10), apiTimer);
                      } else {
                        controller?.animateCamera(
                            CameraUpdate.newCameraPosition(CameraPosition(
                                target: current!.position,
                                zoom: 16.0,
                                tilt: 0.0,
                                bearing: 0.0)));
                      }
                    }
                    navigating = !navigating;
                  });
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primaryContainer),
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.onBackground),
                ),
                // child: const Text("Select Destination")),
              ),
              // ),
            )
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: MapplsMap(
                myLocationEnabled: true,
                myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
                myLocationRenderMode: myLocationRenderMode,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(28.359720, 75.583702),
                  zoom: 15.0,
                ),
                onMapCreated: (mapController) => {controller = mapController},
                onMapLongClick: (point, latLng) {
                  setState(() {
                    destination = latLng;
                    requestLoc = true;
                  });
                },
                onUserLocationUpdated: (location) {
                  current = location;
                },
                onStyleLoadedCallback: () {
                  setState(() => loaded = true);
                },
              ),
            ),
          ),
        ),
        // if (nextPothole != null)
        //   FutureBuilder(
        //     future: http.get(Uri.parse(
        //         'https://apis.mappls.com/advancedmaps/v1/${REST_API_KEY}/rev_geocode/?lat=${nextPothole!.latitude}&lng=${nextPothole!.longitude}')),
        //     builder: (context, snapshot) {
        //       if (snapshot.hasData) {
        //         final data =
        //             jsonDecode(snapshot.data!.body)["results"][0]["street"];
        //         return Text("Next Pothole: $data");
        //       }
        //       return const Text("");
        //     },
        //   ),
      ],
    );
  }
}
