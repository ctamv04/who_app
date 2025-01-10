import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:who_app/pages/home_page.dart';
import 'firebase_options.dart';
import 'models/form.dart' as form_model;
import 'models/page.dart' as page_model;
import 'models/selection.dart';
import 'models/text.dart' as text_model;
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  var form = form_model.Form(title: "default2", pages: {1: page_model.Page(title: "page1", pageNumber: 1, description: "descriptionPage", elements: {1: text_model.Text(title: "text1", subTitle: "subtitle1", required: false, text: ""), 2: Selection(title: "text1", subTitle: "subtitle1", selections: {"option1": false, "option2": false}, required: true, other: true)}), 2: page_model.Page(title: "page2", pageNumber: 2, description: "descriptionPage", elements: {1: Selection(title: "text1", subTitle: "subtitle1", required: true, selections: {"option1": false, "option2": true, "option3": true}, numSelections: 2)})});
  final json = form.toJson();
  final db = FirebaseFirestore.instance;
  db.collection("forms").add(json);

  var snap = await db.collection("forms").get();
  var forms = snap.docs.map((x) => form_model.Form.fromJson(x.data())).toList();

  // runApp(MaterialApp(
  //     title: 'WHO Form Manager',
  //     routes: {
  //       '/': (context) => HomePage(db: db),
  //     },
  //     initialRoute: '/',
  // ));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-33.86, 151.20);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Sample App'),
          backgroundColor: Colors.green[700],
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ),
        ),
      ),
    );
  }
}