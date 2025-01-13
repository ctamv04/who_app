import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class MapWidget extends StatefulWidget {

  String _address;

  LatLng _coordinates;

  MapWidget({
    super.key,
    required String address,
    required LatLng coordinates
  }) : _coordinates = coordinates,
        _address = address;

  @override
  State<MapWidget> createState() => TextFieldDetectionState();
}

class TextFieldDetectionState extends State<MapWidget> {

  late GoogleMapController _mapController;

  String _sessionToken = Uuid().v4();

  late Iterable<Location> _lastSuggestions = <Location>[];

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMapLocation(LatLng newLocation) {
    _mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
  }

  Future<LatLng> getLocation() async {

    if(widget._coordinates == LatLng(0,0)){
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      widget._coordinates = LatLng(position.latitude, position.longitude);
    }

    return widget._coordinates;
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
        future: getLocation(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Text('Loading');
          }

          return Stack(
            children: <Widget>[
              SizedBox(
                  height: 500,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: widget._coordinates,
                      zoom: 20.0,
                    ),
                  )
              ),
              SizedBox(
                height: 500,
                child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50.0,
                    )
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: SizedBox(
                    width: 300,
                    child: Container(
                      color: Colors.white,
                      child: Autocomplete<Location>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {

                          String text = textEditingValue.text;

                          if (text.isEmpty) {
                            return const Iterable<Location>.empty();
                          }

                          String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?key=AIzaSyA9T-d0U9H9EmqMPP1Tm8VSaqARGt3C-8M';
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
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Enter address', // Change this to your desired hint text
                              )
                          );
                        },
                        onSelected: (Location selection) async {

                          String placeID  = selection._id;
                          String baseURL = 'https://maps.googleapis.com/maps/api/place/details/json?key=AIzaSyA9T-d0U9H9EmqMPP1Tm8VSaqARGt3C-8M&fields=formatted_address,geometry';
                          String request = '$baseURL&place_id=$placeID&sessiontoken=$_sessionToken';
                          var response = await http.get(Uri.parse(request));
                          Map<String, dynamic> result = json.decode(response.body)['result'];

                          widget._address = result['formatted_address'] as String;
                          widget._coordinates = LatLng(result['geometry']['location']['lat'] as double, result['geometry']['location']['lng'] as double);
                          _updateMapLocation(widget._coordinates);

                          _sessionToken = Uuid().v4();
                        },
                      ),
                    )
                ),
              )
            ],
          );;
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