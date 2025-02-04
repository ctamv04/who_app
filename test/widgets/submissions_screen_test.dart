import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';import 'package:who_app/screens/signup_screen.dart';
import 'package:who_app/screens/submissions_screen.dart';
import 'submissions_screen_test.mocks.dart';
import 'dart:io';

@GenerateMocks([PathProviderPlatform])
@GenerateMocks([File])

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  late MockPathProviderPlatform mockPathProviderPlatform;
  late MockFile mockFile;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();

    // Mock-Setups
    await mockFirestore.collection('filled_forms').doc('123456789123456789').set({
      'date': DateTime(2025).toString(),
      'uid': 'someuid',
      'form_id': '123456789123456789'
    });
    // await mockFirestore.collection('forms').add({
    //   'title': 'Form 2'
    // });

    // mockPathProviderPlatform = MockPathProviderPlatform();
    // when(mockPathProviderPlatform.getApplicationDocumentsPath()).thenAnswer((_) async => 'dummy');
    //
    // mockFile = MockFile();
    // File file = File();
    // when(File('dummy')).thenReturn(mockFile);

    mockUser = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: 'test@example.com',
      displayName: 'Bob',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser);
    mockAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password');
  });

  testWidgets('Submissions shown logged in', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SubmissionsScreen(formId: '123456789123456789', formTitle: 'form', db: mockFirestore, auth: mockAuth),
      ),
    );

    final aa = (await mockFirestore.collection("filled_forms").where('uid', isEqualTo: 'someuid').where('form_id', isEqualTo: '123456789123456789').get());

    await tester.pump(Duration(seconds: 2));

    final listView = find.byType(ListView);

    expect(listView, findsOneWidget);

    final listTiles = find.descendant(
      of: listView,
      matching: find.byType(ListTile),
    );

    expect(find.text('56789: 2025-01-01 00:00:00.000'), findsOneWidget);
  });

  testWidgets('Submissions shown not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SubmissionsScreen(formId: '123456789123456789', formTitle: 'form', db: mockFirestore, auth: MockFirebaseAuth()),
      ),
    );

    await tester.pumpAndSettle();

    final listView = find.byType(ListView);

    expect(listView, findsOneWidget);

    final listTiles = find.descendant(
      of: listView,
      matching: find.byType(ListTile),
    );

    expect(listView, findsNothing);
  });

  testWidgets('FormListScreen navigates to SubmissionsScreen when a form is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FormListScreen(db: mockFirestore, auth: mockAuth),
        routes: {
          '/profile': (context) => Scaffold(),
        },
      ),
    );

  await tester.pumpAndSettle();

  expect(find.text('Form 1'), findsOneWidget);
  expect(find.text('Form 2'), findsOneWidget);

  await tester.tap(find.text('Form 1'));

  await tester.pump();
  await tester.pump();

  expect(find.byType(SubmissionsScreen), findsOneWidget);
  });

    testWidgets('FormListScreen shows sign in button when user is not logged in', (WidgetTester tester) async {
    mockAuth = MockFirebaseAuth(mockUser: null); // No user logged in

    await tester.pumpWidget(
      MaterialApp(
        home: FormListScreen(db: mockFirestore, auth: mockAuth),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
  });
}