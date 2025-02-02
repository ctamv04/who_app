import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:who_app/models/location.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/profile_screen.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'firebase_options.dart';
import 'models/form.dart' as form_model;
import 'models/text.dart' as text_model;
import '../models/page.dart' as page_model;
import 'package:responsive_framework/responsive_framework.dart';
import '../models/selection.dart';
import '../models/image_element.dart' as image_model;

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: "who-facility-repurposing-forms",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;



//   var form = form_model.Form(
//   title: "Form with Multiple Images",
//   pages: {
//     1: page_model.Page(
//       title: "Image Upload Page",
//       elements: {
//         2: image_model.ImagePickerElement(
//           title: "Upload Images",
//           subTitle: "Select images", 
//           fileNames: [],
//           downloadUrls: [], 
//         ),
//       },
//     ),
//   },
// );

// final json = form.toJson();
// print(json);
// db.collection("forms").add(json);
  // var form = form_model.Form(title: "map", pages: {1: page_model.Page(title: "page1", description: "descriptionPage", elements: {1: text_model.Text(title: "text1", subTitle: "subtitle1", required: false, text: ""), 2: Selection(title: "text1", subTitle: "subtitle1", selections: {"option1": false, "option2": false}, required: true, other: true), 3: Location(title: "loc", subTitle: "locsub")})});
  // final json = form.toJson();
  // db.collection("forms").add(json);
  //
  // var snap = await db.collection("forms").get();
  // var forms = snap.docs.map((x) => form_model.Form.fromJson(x.data())).toList();

  // var form = form_model.Form(title: "Annexe 1. Required technical documents", pages: {
  //   1: page_model.Page(title: "General information", description: "Applicant details", elements: {
  //     1: text_model.Text(title: "Institution", subTitle: "Name of the institution/hospital where the center will be installed/built/rehabilitated.", required: true, special: 'institution'),
  //     2: text_model.Text(title: "Full name", subTitle: "Full name of the contact person.", required: true, special: 'name'),
  //     3: text_model.Text(title: "Position", subTitle: "Position of the contact person.", required: true, special: 'position'),
  //     4: text_model.Text(title: "Phone", subTitle: "Phone number of the contact person.", required: true, special: 'phone'),
  //     5: text_model.Text(title: "Mail", subTitle: "Mail of the contact person", required: true, special: 'email'),
  //     6: text_model.Text(title: "City", required: true, special: 'city'),
  //     7: text_model.Text(title: "Unit of measurement", required: true, special: 'unit')}),
  //   2: page_model.Page(title: "General information", elements: {
  //     1: Selection(title: "Requesting for", required: true, numSelections: 1, other: true, selections: {
  //       "Infectious diseases treatment centre ( i.e. Ebola, Marburg, Cholera, COVID-19,…)": false,
  //       "Screening area": false,
  //       "Trauma Center": false,
  //       "Primary Health Care Center": false,
  //       "Surge plan": false,
  //       "Self-quarantine isolation area": false
  //     }),
  //     2: Selection(title: "Type of facility", required: true, numSelections: 1, other: true, selections: {
  //       "New construction": false,
  //       "Repurposing of existing building (non-medical building)": false,
  //       "Retrofitting of existing building (medical building)": false,
  //       "Repurposing of some existing buildings + new constructions": false,
  //     }),
  //     3: Selection(title: "Type of construction", required: true, numSelections: 1, other: true, selections: {
  //       "Traditional structure (concrete, bricks…)": false,
  //       "Prefabricated structure (frame+ panels)": false,
  //       "Wood pillar and plastic sheeting": false,
  //       "Tens and rub-hall": false,
  //       "Containers": false
  //     }),
  //   })
  // });
  // final json = form.toJson();
  // db.collection("forms").add(json);



  
  final auth = FirebaseAuth.instance;
  // auth.signOut();

  Widget home = LoginScreen(db: db, auth: auth);
  final user = auth.currentUser;
  if(user != null || await File('${(await getApplicationDocumentsDirectory()).path}/guest_id.txt').exists()){

    home = FormListScreen(db: db, auth: auth);

    if(user != null && (await db.collection('users').doc(user.uid).get()).data()!['role'] == 'admin'){
      home = FormListScreenAdmin(db: db, auth: auth);
    }
  }

  runApp(MaterialApp(
    builder: (context, child) => ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: [
        const Breakpoint(start: 0, end: 800, name: MOBILE),
        const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
      ],
    ),
    title: 'WHO Form Manager',
    home: home,
    routes: {
      '/forms': (context) => FormListScreen(db: db, auth: auth),
      '/forms_admin': (context) => FormListScreenAdmin(db: db, auth: auth),
      '/login': (context) => LoginScreen(db: db, auth: auth),
      '/profile': (context) => ProfileScreen(db: db, auth: auth)
    },
  ));
}