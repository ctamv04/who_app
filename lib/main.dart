import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:who_app/models/location.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/home_screen.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'firebase_options.dart';
import 'models/form.dart' as form_model;
import 'models/selection.dart';
import 'models/text.dart' as text_model;
import '../models/page.dart' as page_model;
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  var form = form_model.Form(title: "map", pages: {1: page_model.Page(title: "page1", description: "descriptionPage", elements: {1: text_model.Text(title: "text1", subTitle: "subtitle1", required: false, text: ""), 2: Selection(title: "text1", subTitle: "subtitle1", selections: {"option1": false, "option2": false}, required: true, other: true), 3: Location(title: "loc", subTitle: "locsub")})});
  final json = form.toJson();
  final db = FirebaseFirestore.instance;
  db.collection("forms").add(json);

  var snap = await db.collection("forms").get();
  var forms = snap.docs.map((x) => form_model.Form.fromJson(x.data())).toList();

  final auth = FirebaseAuth.instance;

  runApp(MaterialApp.router(
    builder: (context, child) => ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: [
        const Breakpoint(start: 0, end: 800, name: MOBILE),
        const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
      ],
    ),
    title: 'WHO Form Manager',
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/forms',
          builder: (context, state) => FormListScreen(db: db),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(db: db, auth: auth),
        ),
      ],
      initialLocation: auth.currentUser != null ? '/forms' : 'login'
    ),
  ));
}