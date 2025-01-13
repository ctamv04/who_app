import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:who_app/models/location_page.dart';
import 'package:who_app/pages/text_field_detection.dart';
import '../models/page.dart' as page_model;

class MapPage extends StatefulWidget {

  final Map<String, dynamic> _form;

  final Map<int, page_model.Page> _computedPages;

  final int _pageNumber;

  final FirebaseFirestore _db;

  MapPage({
    super.key,
    required Map<String, dynamic> form,
    required int pageNumber,
    required Map<int, page_model.Page> computedPages,
    required FirebaseFirestore db
  }) : _form = form,
        _pageNumber = pageNumber,
        _computedPages = computedPages..[pageNumber] = page_model.Page.fromJson(form['pages'][pageNumber.toString()]),
        _db = db;

  @override
  State<MapPage> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapPage> {

  late GoogleMapController _mapController;

  late LocationPage _page;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> updateMap(String address) async {

    // if (locations.isNotEmpty) {
    //   setState(() {
    //     _coordinates =
    //         LatLng(locations.first.latitude, locations.first.longitude);
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {

    _page = widget._computedPages[widget._pageNumber]! as LocationPage;

    List<Widget> actions = [];
    if(widget._form['pages'][(widget._pageNumber+1).toString()] != null){
      actions.add(
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Next page',
            onPressed: () {

            },
          )
      );
    }else{
      actions.add(
          TextButton(
            onPressed: () {

            },
            child: const Text('Submit'),
          )
      );
    }

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(_page.title),
          actions: actions
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 11.0,
                ),
              )
          ),
          Positioned(
              top: 50,
              left: 50,
              child: TextFieldDetection()
          ),
        ],
      )
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFieldDetection(),
            ListView(
                shrinkWrap: true,
                children: [
                  SizedBox(
                      height: 500,
                      width: double.infinity,
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(38, 23),
                          zoom: 11.0,
                        ),
                      )
                  )
                ]
            )
          ]
      ),
    );


      Stack(
      children: <Widget>[
        Positioned.fill(
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(0, 0),
              zoom: 11.0,
            ),
          )
        ),
        Positioned(
            top: 50,
            left: 50,
            child: TextFieldDetection()
        ),
      ],
    );
  }
}
