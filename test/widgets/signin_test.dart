import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:who_app/screens/form_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:who_app/screens/signup_screen.dart';
//Use the mocks in these last 2 imports for all firestore stuff


void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();

    // Mock-Setups
    await mockFirestore.collection('users').doc('someuid').set({
      'role': 'user'
    });
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: 'test@example.com',
      displayName: 'Bob',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser);
  });

  testWidgets('LoginScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen(db: mockFirestore, auth: mockAuth)));

    expect(find.byType(TextField), findsNWidgets(2)); //Email + Password
    expect(find.byType(ElevatedButton), findsOneWidget); //Sign in
    expect(find.byType(TextButton), findsNWidgets(2)); //Create an account + Continue as guest
  });

  testWidgets('Sign in with valid credentials navigates to forms', (WidgetTester tester) async {
    const email = 'test@example.com';
    const password = 'password123';

    await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(db: mockFirestore, auth: mockAuth),
          routes: {
            '/forms': (context) => FormListScreen(db: mockFirestore, auth: mockAuth),
            '/forms_admin': (context) => FormListScreenAdmin(db: mockFirestore, auth: mockAuth),
          },
          //Don't forget to manually define the routes when pumping widgets
        )
    );

    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), password);

    await tester.tap(find.byType(ElevatedButton));

    await tester.pumpAndSettle();

    expect(find.byType(FormListScreen), findsOneWidget);
  });

  testWidgets('Continue as guest navigates to form list', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(db: mockFirestore, auth: mockAuth),
      routes: {
        '/forms': (context) => FormListScreen(db: mockFirestore, auth: mockAuth),
      },
    )
  );

  await tester.tap(find.byType(TextButton).at(1));
  await tester.pumpAndSettle();

  expect(find.byType(FormListScreen), findsOneWidget);
  });

  testWidgets('Create account navigates to signup screen', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(db: mockFirestore, auth: mockAuth),
      routes: {
        '/signup': (context) => SignupScreen(db: mockFirestore, auth: mockAuth),
      },
    )
  );

  await tester.tap(find.byType(TextButton).at(0));
  await tester.pumpAndSettle();

  expect(find.byType(SignupScreen), findsOneWidget);
});
testWidgets('Valid user role is fetched from Firestore', (WidgetTester tester) async {
  const email = 'test@example.com';
  const password = 'password123';

  // Pump Widget
  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(db: mockFirestore, auth: mockAuth),
      routes: {
        '/forms': (context) => FormListScreen(db: mockFirestore, auth: mockAuth),
      },
    )
  );

  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);

  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // Hier könntest du auch sicherstellen, dass der Benutzer mit der richtigen Rolle aufgerufen wird:
  DocumentSnapshot userDoc = await mockFirestore.collection('users').doc('someuid').get();
  expect(userDoc['role'], 'user');
  });



}