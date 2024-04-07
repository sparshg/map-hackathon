import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map/utils.dart';
import 'package:mappls_gl/mappls_gl.dart';

class AddGradientPolyline extends StatefulWidget {
  const AddGradientPolyline({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddGradientPolylineState();
  }
}

class _AddGradientPolylineState extends State {
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(28.705436, 77.100462),
    zoom: 14.0,
  );

  late MapplsMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Gradient Polyline'),
        ),
        body: MapplsMap(
          initialCameraPosition: _kInitialPosition,
          onMapCreated: (mapController) {
            this.mapController = mapController;
          },
          onStyleLoadedCallback: () {
            List<List<double>> coords = [
              [77.100462, 28.705436],
              [77.100784, 28.705191],
              [77.101514, 28.704646],
              [77.101171, 28.704194],
              [77.101066, 28.704083],
              [77.101318, 28.703900]
            ];
            gradientPolyLine(mapController, coords);
          },
        ));
  }

  _onStyleLoadedCallback() async {
    await mapController.addSource(
        "gradient-line-source-id",
        GeojsonSourceProperties(
            data: _polylineFeature, lineMetrics: true, buffer: 2.0));

    await mapController.addLineLayer(
        "gradient-line-source-id",
        "gradient-line-layer-id",
        const LineLayerProperties(lineGradient: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.lineProgress],
          0,
          "#FFFFFF",
          0.5,
          "#FFFFFF",
          1,
          "#000000"
        ], lineWidth: 4.0));
  }

  final _polylineFeature = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [77.100462, 28.705436],
            [77.100784, 28.705191],
            [77.101514, 28.704646],
            [77.101171, 28.704194],
            [77.101066, 28.704083],
            [77.101318, 28.703900]
          ]
        },
      }
    ]
  };
}
