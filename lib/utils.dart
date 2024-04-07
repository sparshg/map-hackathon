import 'package:flutter/material.dart';
import 'package:map/polyline.dart';
import 'package:mappls_gl/mappls_gl.dart';

Future<List<LatLng>?> getDirection(LatLng origin, LatLng dest) async {
  DirectionResponse? directionResponse = await MapplsDirection(
    origin: origin,
    destination: dest,
    alternatives: false,
    steps: true,
    overview: DirectionCriteria.OVERVIEW_SIMPLIFIED,
  ).callDirection();

  if (directionResponse != null &&
      directionResponse.routes != null &&
      directionResponse.routes!.isNotEmpty) {
    // setState(() {
    //   route = directionResponse.routes![0];
    // });
    Polyline polyline = Polyline.decode(
        encodedString: directionResponse.routes![0].geometry, precision: 6);
    List<LatLng> latlngList = [];
    if (polyline.decodedCoords != null) {
      polyline.decodedCoords?.forEach((element) {
        latlngList.add(LatLng(element[0], element[1]));
      });
    }
    // for (int i = 0; i < latlngList.length; i++) {
    //   controller?.addSymbol(SymbolOptions(
    //     geometry: latlngList[i],
    //     iconImage: 'assets/custom-icon.png',
    //     iconSize: 0.5,
    //     iconAnchor: 'bottom',
    //   ));
    // }
    // drawPath(latlngList, controller);
    return latlngList;
  }
  return null;
}

void drawPath(List<LatLng> latlngList, MapplsMapController? controller) {
  controller?.addLine(LineOptions(
    geometry: latlngList,
    lineColor: "#3bb2d0",
    lineWidth: 4,
  ));
  LatLngBounds latLngBounds = boundsFromLatLngList(latlngList);
  controller?.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds,
      top: 100, bottom: 20, left: 10, right: 10));
}

boundsFromLatLngList(List<LatLng> list) {
  assert(list.isNotEmpty);
  double? x0, x1, y0, y1;
  for (LatLng latLng in list) {
    if (x0 == null || x1 == null || y0 == null || y1 == null) {
      x0 = x1 = latLng.latitude;
      y0 = y1 = latLng.longitude;
    } else {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
  }
  return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
}

void showSnackBar(BuildContext context, String s) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(s),
    duration: const Duration(seconds: 2),
  ));
}

void gradientPolyLine(
    MapplsMapController? controller, List<List<double>> coords) async {
  final polylineFeature = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {"type": "LineString", "coordinates": coords},
      }
    ]
  };
  await controller?.removeLayer("gradient-line-layer-id");
  await controller?.removeSource("gradient-line-source-id");
  await controller?.addSource(
      "gradient-line-source-id",
      GeojsonSourceProperties(
          data: polylineFeature, lineMetrics: true, buffer: 2.0));

  await controller?.addLineLayer(
      "gradient-line-source-id",
      "gradient-line-layer-id",
      const LineLayerProperties(lineGradient: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.lineProgress],
        0,
        "#3dd2d0",
        0.5,
        "#000000",
        1,
        "#FF20d0"
      ], lineWidth: 4.0));
}
