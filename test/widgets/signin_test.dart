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
//Use the mocks in these last 2 imports for all firestore stuff

// Erstelle Mock-Klassen
// class MockFirebaseAuth extends Mock implements FirebaseAuth {}
// class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
// class MockUserCredential extends Mock implements UserCredential {}
// class MockUser extends Mock implements User {
//   @override
//   String get uid => '12345';  // Direkte Zuweisung
// }

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() async {
    // Initialisiere die Mocks
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

    expect(find.byType(TextField), findsNWidgets(2)); 
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget); 
  });

  testWidgets('Sign in with valid credentials navigates to forms', (WidgetTester tester) async {
    const email = 'test@example.com';
    const password = 'password123';

    // final mockUserCredential = MockUserCredential();
    //
    // when(mockAuth.signInWithEmailAndPassword(email: email, password: password))
    //     .thenAnswer((_) async => MockUserCredential());

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
}