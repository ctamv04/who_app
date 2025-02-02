
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:who_app/screens/form_screen.dart';

// Erstelle Mock-Klassen
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {
  @override
  String get uid => '12345';  // Direkte Zuweisung
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() {
    // Initialisiere die Mocks
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();

    // Mock-Setups
    when(mockAuth.currentUser).thenReturn(mockUser);
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

    final mockUserCredential = MockUserCredential();

    when(mockAuth.signInWithEmailAndPassword(email: email, password: password))
        .thenAnswer((_) async => mockUserCredential);

    await tester.pumpWidget(MaterialApp(home: LoginScreen(db: mockFirestore, auth: mockAuth)));

    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), password);

    await tester.tap(find.byType(ElevatedButton));

    await tester.pumpAndSettle();

    expect(find.byType(FormScreen), findsOneWidget); 
  });
}