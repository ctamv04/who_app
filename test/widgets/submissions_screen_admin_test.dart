import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:who_app/screens/admin/submissions_screen_admin.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();

    await mockFirestore.collection('users').doc('adminuid').set({
      'role': 'admin'
    });
    await mockFirestore.collection('forms').doc('formId').set({
      'title': 'Test Form'
    });
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'adminuid',
      email: 'test@example.com',
      displayName: 'Admin User',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser);
  });


  testWidgets('SubmissionsScreenAdmin redirects to login if user is not an admin', (WidgetTester tester) async {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'user123',
      email: 'user@example.com',
      displayName: 'Regular User',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser);

    await tester.pumpWidget(MaterialApp(
      home: SubmissionsScreenAdmin(
        formId: 'formId',
        formTitle: 'Test Form',
        db: mockFirestore,
        auth: mockAuth,
      ),
      routes: {
        '/login': (context) => LoginScreen(db: mockFirestore, auth: mockAuth),
      },
    ));

    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Not authorized to access this page. Please sign in.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
