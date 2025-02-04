import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/signin_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:who_app/main.dart' as app;

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();

    await mockFirestore.collection('users').doc('user123').set({'role': 'user'});
    await mockFirestore.collection('users').doc('admin123').set({'role': 'admin'});

    mockUser = MockUser(uid: 'user123', email: 'test@example.com', displayName: 'TestUser');
  });

  testWidgets('Main app launches', (WidgetTester tester) async {
    app.startApp(mockFirestore, mockAuth);
    await tester.pumpAndSettle(); 

    //expect(find.byType(LoginScreen), findsOneWidget);
  });


  testWidgets('Not logged-in users see LoginScreen', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(home: LoginScreen(db: mockFirestore, auth: mockAuth)));

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Logged-in users see FormListScreen', (WidgetTester tester) async {
    mockAuth = MockFirebaseAuth(mockUser: mockUser);

    await tester.pumpWidget(MaterialApp(home: FormListScreen(db: mockFirestore, auth: mockAuth)));

    expect(find.byType(FormListScreen), findsOneWidget);
  });

  testWidgets('Admins see FormListScreenAdmin', (WidgetTester tester) async {
    mockAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'admin123'));

    await tester.pumpWidget(
      MaterialApp(
        home: FormListScreenAdmin(db: mockFirestore, auth: mockAuth),
        routes: {
          '/forms': (context) => FormListScreen(db: mockFirestore, auth: mockAuth),
          '/forms_admin': (context) => FormListScreenAdmin(db: mockFirestore, auth: mockAuth),
          '/login': (context) => LoginScreen(db: mockFirestore, auth: mockAuth),
        },
      )
      
    );

    expect(find.byType(FormListScreenAdmin), findsOneWidget);
  });
}
