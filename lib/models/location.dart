import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'form_element.dart';

class Location extends FormElement {

  String _address;

  LatLng _coordinates;

  Location({
    required super.title,
    super.subTitle,
    super.required,
    String? address,
    LatLng? coordinates
  }) : _address = address ?? "",
        _coordinates = coordinates ?? LatLng(45.4685, 9.1824);

  factory Location.fromJson(Map<String, dynamic> json) {

    Map<String, dynamic> coordinates = json['coordinates'];
    return Location(
      title: json['title'] as String,
      subTitle: json['subtitle'] as String,
      required: json['required'] as bool,
      address: json['address'] as String?,
      coordinates: LatLng(coordinates['lat'] as double, coordinates['long'] as double)
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {
        'title': super.title,
        'subtitle': super.subTitle,
        'required': super.required,
        'type': "location",
        'address': _address,
        'coordinates': {
          'lat': _coordinates.latitude,
          'long': _coordinates.longitude
        }
      };

  String get address => _address;
  LatLng get coordinates => _coordinates;

  set address(String? address) => _address = address ?? "";
  set coordinates(LatLng? coordinates) => _coordinates = coordinates ?? LatLng(0, 0);
}