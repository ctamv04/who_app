import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:who_app/models/location.dart';
import 'package:who_app/models/location_page.dart';
import 'package:who_app/pages/home_page.dart';
import 'firebase_options.dart';
import 'models/form.dart' as form_model;
import 'models/field_page.dart';
import 'models/selection.dart';
import 'models/text.dart' as text_model;

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  var form = form_model.Form(title: "map", pages: {1: FieldPage(title: "page1", description: "descriptionPage", elements: {1: text_model.Text(title: "text1", subTitle: "subtitle1", required: false, text: ""), 2: Selection(title: "text1", subTitle: "subtitle1", selections: {"option1": false, "option2": false}, required: true, other: true), 3: Location(title: "loc", subTitle: "locsub")})});
  final json = form.toJson();
  final db = FirebaseFirestore.instance;
  db.collection("forms").add(json);

  var snap = await db.collection("forms").get();
  var forms = snap.docs.map((x) => form_model.Form.fromJson(x.data())).toList();

  runApp(MaterialApp(
      title: 'WHO Form Manager',
      routes: {
        '/': (context) => HomePage(db: db),
      },
      initialRoute: '/',
  ));
}