  import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:who_app/screens/profile_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:who_app/screens/signup_screen.dart';


void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();

    mockUser = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: 'test@example.com',
      displayName: 'Bob',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser);
    mockAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password');

    await mockFirestore.collection('users').doc('someuid').set({
      'name': 'Test',
      'position': 'Dev',
      'institution': 'University',
      'phone': '+0123456789',
      'city': 'Milan',
      'country': 'Italy',
      'unit': 'kg',
      'role': 'user',
    });
  });

  testWidgets('ProfileScreen displays user data', (WidgetTester tester) async {
    mockAuth.signInWithCustomToken('someuid');
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(db: mockFirestore, auth: mockAuth, testing: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test'), findsOneWidget);
  });

  testWidgets('Edit', (WidgetTester tester) async {
    mockAuth.signInWithCustomToken('someuid');
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(db: mockFirestore, auth: mockAuth, testing: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dev'), findsOneWidget);

    final button = find.byIcon(Icons.edit_rounded);

    expect(button, findsOneWidget);

    await tester.tap(button);

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'Engineer');

    await tester.tap(find.byIcon(Icons.check_circle));

    await tester.pumpAndSettle();

    expect(find.text('Engineer'), findsOneWidget);
  });

  testWidgets('Edit Cancel', (WidgetTester tester) async {
    mockAuth.signInWithCustomToken('someuid');
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(db: mockFirestore, auth: mockAuth, testing: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Italy'), findsOneWidget);

    final button = find.byIcon(Icons.edit_rounded);

    expect(button, findsOneWidget);

    await tester.tap(button);

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'Japan');

    await tester.tap(find.byIcon(Icons.cancel));

    await tester.pumpAndSettle();

    expect(find.text('Italy'), findsOneWidget);
  });

  testWidgets('Log out', (WidgetTester tester) async {
    mockAuth.signInWithCustomToken('someuid');
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(db: mockFirestore, auth: mockAuth),
        routes: {
          '/login': (context) => LoginScreen(db: mockFirestore, auth: mockAuth),
        },
      ),
    );

    await tester.pumpAndSettle();

    mockAuth.signOut();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}