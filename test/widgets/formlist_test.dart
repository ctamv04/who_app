import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:who_app/screens/signup_screen.dart';
import 'package:who_app/screens/submissions_screen.dart';
//Use the mocks in these last 2 imports for all firestore stuff


void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();

    // Mock-Setups
    await mockFirestore.collection('forms').add({
      'title': 'Form 1'
    });
    await mockFirestore.collection('forms').add({
      'title': 'Form 2'
    });

    mockUser = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: 'test@example.com',
      displayName: 'Bob',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser);
  });

  testWidgets('FormListScreen shows list of forms', (WidgetTester tester) async {
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

  testWidgets('No forms check', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FormListScreen(db: FakeFirebaseFirestore(), auth: mockAuth),
        routes: {
          '/profile': (context) => Scaffold(),
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("There are no forms available."), findsOne);
  });
}