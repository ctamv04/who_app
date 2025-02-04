import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:who_app/firebase_options.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/form_screen.dart';
import 'package:who_app/screens/form_screen_readonly.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:who_app/screens/signup_screen.dart';
import 'package:who_app/screens/submissions_screen.dart';
import 'dart:io';
import 'package:who_app/models/form.dart' as form_model;
import 'package:who_app/models/text.dart' as text_model;
import 'package:who_app/models/page.dart' as page_model;
import 'package:who_app/models/selection.dart';
import 'package:who_app/models/image_element.dart' as image_model;

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  FirebaseFirestore? db;
  late MockUser mockUser;

  setUpAll(() async {
    // WidgetsFlutterBinding.ensureInitialized();
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // db = FirebaseFirestore.instance;
    // db!.settings = const Settings(persistenceEnabled: false, sslEnabled: false);
    // db!.useFirestoreEmulator('localhost', 8080);
  });

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();

    // Mock-Setups
    final form = form_model.Form(title: 'form', pages: {1 : page_model.Page(title: 'title')}).toJson();
    form['date'] = DateTime(2025).toString();
    form['uid'] = 'someuid';
    form['form_id'] = '123456789123456789';
    // await db!.collection('filled_forms').doc('123456789123456789').set(form);
    await mockFirestore.collection('filled_forms').doc('123456789123456789').set(form);
    await mockFirestore.collection('forms').doc('123456789123456789').set(form);
    await mockFirestore.collection('users').doc('someuid').set({
      'name': 'ab'
    });

    mockUser = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: 'test@example.com',
      displayName: 'Bob',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser);
    mockAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password');
  });

  testWidgets('Check floating button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SubmissionsScreen(formId: '123456789123456789', formTitle: 'form', db: mockFirestore, auth: mockAuth),
      ),
    );

    await tester.pumpAndSettle();

    final button = find.byType(FloatingActionButton);

    expect(button, findsOneWidget);

    await tester.tap(button);

    await tester.pumpAndSettle();
    expect(find.byType(FormScreen), findsOneWidget);
  });

  testWidgets('No forms check', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SubmissionsScreen(formId: '123456789123456789', formTitle: 'form', db: mockFirestore, auth: MockFirebaseAuth(), testing: true),
      ),
    );

    // await tester.pumpAndSettle();
    //
    await tester.pump(Duration(seconds: 2));

    expect(find.text("You haven't submitted any forms of this type yet."), findsOne);
  });
}