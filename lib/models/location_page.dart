import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:who_app/models/page.dart';

class LocationPage extends Page {

  bool _required;
  String _address;
  LatLng _coordinates;

  LocationPage({
    required super.title,
    super.description,
    bool? required,
    String? address,
    LatLng? coordinates
  }) : _required = required ?? false, _address = address ?? "", _coordinates = coordinates ?? LatLng(0, 0);

  factory LocationPage.fromJson(Map<String, dynamic> json) {

    Map<String, dynamic> coordinates = json['coordinates'];
    return LocationPage(
      title: json['title'] as String,
      description: json['description'] as String,
      required: json['required'] as bool,
      address: json['address'] as String,
      coordinates: LatLng(coordinates['lat'] as double, coordinates['long'] as double)
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {
        'title': super.title,
        'description': super.description,
        'type': "location",
        'required': _required,
        'address': _address,
        'coordinates': {
          'lat': _coordinates.latitude,
          'long': _coordinates.longitude
        }
      };

  bool get required => _required;
  String get address => _address;
  LatLng get coordinates => _coordinates;
}