import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class MapWidget extends StatefulWidget {

  String _address;

  LatLng _coordinates;

  final bool _required;

  MapWidget({
    super.key,
    required String address,
    required LatLng coordinates,
    required required
  }) : _coordinates = coordinates,
        _address = address,
        _required = required;

  @override
  State<MapWidget> createState() => TextFieldDetectionState();

  String get address => _address;
  LatLng get coordinates => _coordinates;
}

class TextFieldDetectionState extends State<MapWidget> {

  late GoogleMapController _mapController;

  String _sessionToken = Uuid().v4();

  late Iterable<Location> _lastSuggestions = <Location>[];

  bool _init = true;

  final String _mapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1d2c4d"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8ec3b9"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1a3646"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#4b6878"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#64779e"
      }
    ]
  },
  {
    "featureType": "administrative.province",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#4b6878"
      }
    ]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#334e87"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#023e58"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#283d6a"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6f9ba5"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1d2c4d"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#023e58"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#3C7680"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#304a7d"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#98a5be"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1d2c4d"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2c6675"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#255763"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#b0d5ce"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#023e58"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#98a5be"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1d2c4d"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#283d6a"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3a4762"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#0e1626"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#4e6d70"
      }
    ]
  }
]''';

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMapLocation(LatLng newLocation) {
    _mapController.moveCamera(CameraUpdate.newLatLng(newLocation));
  }

  Future<LatLng> getLocation() async {

    LatLng coordinates = widget._coordinates;
    if(_init){

      if(kIsWeb){
        _init = false;
        return coordinates;
      }

      try {
        Geolocator.requestPermission();
        Position position = await Geolocator.getCurrentPosition();

        coordinates = LatLng(position.latitude, position.longitude);
        widget._coordinates = coordinates;
      } catch (e) {
        _init = false;
        return widget._coordinates;
      }
    }

    _init = false;
    return coordinates;
  }

  @override
  Widget build(BuildContext context) {

    LatLng tempTarget = LatLng(0, 0);
    return FutureBuilder(
        future: getLocation(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          return FormField<bool>(
              builder: (state) {
                return Stack(
                  children: <Widget>[
                    SizedBox(
                        height: 500,
                        child: GoogleMap(
                          style: _mapStyle,
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: widget._coordinates,
                            zoom: 10.0,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                            },
                          onCameraMove: (CameraPosition position) {
                            tempTarget = position.target;
                          },
                          onCameraIdle: () {
                            setState(() {
                              widget._coordinates = tempTarget;
                            });
                          },
                        )
                    ),
                    SizedBox(
                      height: 500,
                      child: Align(
                          alignment: FractionalOffset(0.5, 0.45),
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 50.0,
                          )
                      ),
                    ),
                    SizedBox(
                        height: 500,
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              "Lat: ${widget._coordinates.latitude.toStringAsFixed(2)}, Long: ${widget._coordinates.longitude.toStringAsFixed(2)}",
                              style: TextStyle(fontSize: 12),
                            )
                        )
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: SizedBox(
                          width: 250,
                          child: Container(
                            padding: const EdgeInsets.all(1.0),
                            color: Color.fromARGB(200, 255, 255, 255),
                            child: Autocomplete<Location>(
                              optionsBuilder: (TextEditingValue textEditingValue) async {

                                String text = textEditingValue.text;

                                if (text.isEmpty || kIsWeb){
                                  widget._address = text;
                                  return const Iterable<Location>.empty();
                                }

                                if (text.isEmpty){
                                  return const Iterable<Location>.empty();
                                }

                                String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?key=AIzaSyDPDDKJTWjHxj2lEffPCPgqbo-CghXX9b0';
                                String request = '$baseURL&input=$text&sessiontoken=$_sessionToken';
                                var response = await http.get(Uri.parse(request));

                                if (text != textEditingValue.text) {
                                  return _lastSuggestions;
                                }

                                if (response.statusCode == 200) {
                                  List<dynamic> predictions = json.decode(response.body)['predictions'];
                                  return predictions.map((x) => Location(id: x['place_id'] as String, name: x['description'] as String));
                                } else {
                                  return const Iterable<Location>.empty();
                                }
                              },
                              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {

                                textEditingController.text = widget._address;
                                return TextField(
                                    style: TextStyle(
                                      color: Colors.black,

                                    ),
                                    controller: textEditingController,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                        hintText: 'Enter address',
                                        hintStyle: TextStyle(
                                            color: Colors.grey
                                        )
                                    )
                                );
                              },
                              onSelected: (Location selection) async {

                                String placeID  = selection._id;
                                String baseURL = 'https://maps.googleapis.com/maps/api/place/details/json?key=AIzaSyDPDDKJTWjHxj2lEffPCPgqbo-CghXX9b0&fields=formatted_address,geometry';
                                String request = '$baseURL&place_id=$placeID&sessiontoken=$_sessionToken';
                                var response = await http.get(Uri.parse(request));
                                Map<String, dynamic> result = json.decode(response.body)['result'];

                                widget._address = result['formatted_address'] as String;
                                _updateMapLocation(LatLng(result['geometry']['location']['lat'] as double, result['geometry']['location']['lng'] as double));

                                _sessionToken = Uuid().v4();
                              },
                            ),
                          )
                      ),
                    )
                  ],
                );
              },
              validator: (value) {

                if(widget._required && widget._address == ""){
                  return "Please enter a valid address.";
                }

                return null;
              }
          );
        }
    );
  }
}

class Location {

  final String _id;

  final String _name;

  Location({
  required id,
  required name,
  }) : _id = id, _name = name;

  @override
  String toString() {
    return _name;
  }

  @override
  bool operator == (Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Location && other._id == _id;
  }

  @override
  int get hashCode => Object.hash(_id, _name);
}