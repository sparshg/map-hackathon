import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mappls_place_widget/mappls_place_widget.dart';

Future<ReverseGeocodePlace> openMapplsPicker() async {
  ReverseGeocodePlace place;
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    place = await openPlacePicker(PickerOption(
        includeDeviceLocationButton: true,
        includeSearch: true,
        mapMaxZoom: 18,
        mapMinZoom: 5,
        placeOptions: PlaceOptions()));
  } on PlatformException {
    place = ReverseGeocodePlace();
  }
  if (kDebugMode) {
    print(json.encode(place.toJson()));
  }
  return place;
}
