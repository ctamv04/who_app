import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:who_app/screens/signup_screen.dart';


void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();

    // Mock-Setups
    mockAuth = MockFirebaseAuth();
  });

  testWidgets('SignupScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(db: mockFirestore, auth: mockAuth),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(4)); // Name, Email, Password, Confirm 
    expect(find.byType(ElevatedButton), findsOneWidget); // Sign up 
    expect(find.byType(TextButton), findsOneWidget); // Log in
  });

  testWidgets('Signup with valid credentials navigates to login screen', (WidgetTester tester) async {
    const email = 'test@example.com';
    const password = 'Password123!';
    const name = 'Test User';

    await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(db: mockFirestore, auth: mockAuth),
          routes: {
            '/login': (context) => FormListScreen(db: mockFirestore, auth: mockAuth),
          },
        )
    );

    await tester.enterText(find.byType(TextField).at(0), name); // Name
    await tester.enterText(find.byType(TextField).at(1), email); // Email
    await tester.enterText(find.byType(TextField).at(2), password); // Password
    await tester.enterText(find.byType(TextField).at(3), password); // Confirm Password

    await tester.tap(find.byType(ElevatedButton));

    await tester.pumpAndSettle();

    expect(find.byType(FormListScreen), findsOneWidget);
  });

  testWidgets('Signup with passwords that do not match shows error message', (WidgetTester tester) async {
    const email = 'test@example.com';
    const password = 'Password123!';
    const confirmPassword = 'DifferentPassword!';
    const name = 'Test User';

    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(db: mockFirestore, auth: mockAuth),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), name);
    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.enterText(find.byType(TextField).at(2), password);
    await tester.enterText(find.byType(TextField).at(3), confirmPassword);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('- Passwords do not match'), findsOneWidget);
  });
}