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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMapLocation(LatLng newLocation) {
    _mapController.moveCamera(CameraUpdate.newLatLng(newLocation));
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

          return FormField<bool>(
              builder: (state) {
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
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          onCameraMove: (CameraPosition position) {
                            widget._coordinates = position.target;
                          },
                          onCameraIdle: () {
                            setState(() {});
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
                            child: Container(
                                color: Colors.white,
                                child: Text(
                                  "Lat: ${widget._coordinates.latitude.toStringAsFixed(2)}, Long: ${widget._coordinates.longitude.toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 18),
                                )
                            )
                        )
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