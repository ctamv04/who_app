import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart';
import 'package:who_app/screens/admin/form_list_screen_admin.dart';
import 'package:who_app/screens/form_list_screen.dart';
import 'package:who_app/screens/form_screen.dart';
import 'package:who_app/models/form.dart' as form_model;
import 'package:who_app/models/page.dart' as page_model;
import 'package:who_app/models/text.dart' as text_model;
import 'package:who_app/screens/signin_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:who_app/screens/signup_screen.dart';
import 'package:who_app/screens/submissions_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';


class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late FirebaseStorage mockStorage;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockStorage = MockFirebaseStorage();
  });

  testWidgets('FormScreen renders with form data', (WidgetTester tester) async {
    
    final page = page_model.Page(
      title: "Page 1", 
      description: "descriptionPage", 
      elements: {
        1: text_model.Text(
          title: "Text 1", 
          subTitle: "Subtitle 1", 
          required: false, 
          text: ""
        )
      }
    );

    final formData = form_model.Form(
      title: "Test Form", 
      pages: {0: page},
    ).toJson();
  

    final pages = formData['pages'];

    final Map<String, dynamic> firstPage = pages['0'] as Map<String, dynamic>;

    expect(firstPage, isNotNull);
    expect(firstPage['title'], equals('Page 1'));
    expect(firstPage['description'], equals('descriptionPage'));

    await tester.pumpWidget(
    MaterialApp(
      home: FormScreen(
        formId: 'testFormId',
        form: formData,
        pageNumber: 0,
        computedPages: {},
        screenshots: {},
        db: mockFirestore,
        auth: mockAuth,
      ),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('Text 1'), findsOneWidget);
  expect(find.text('Subtitle 1'), findsOneWidget);
  });
  
  testWidgets('Next button navigates to next page', (WidgetTester tester) async {
    final page = page_model.Page(
      title: "Page 1", 
      description: "descriptionPage", 
      elements: {
        0: text_model.Text(
          title: "Text 1", 
          subTitle: "Subtitle 1", 
          required: false, 
          text: ""
        ),
      }
    );

    final page2 = page_model.Page(
      title: "Page 2", 
      description: "descriptionPage2", 
      elements: {
        0: text_model.Text(
          title: "Text 2", 
          subTitle: "Subtitle 2", 
          required: false, 
          text: ""
        ),
      }
    );

    final formData = form_model.Form(
      title: "Test Form", 
      pages: {
        0: page, 
        1: page2,
      },
    ).toJson();

    await tester.pumpWidget(
      MaterialApp(
        home: FormScreen(
          formId: 'testFormId',
          form: formData,
          pageNumber: 0,
          computedPages: {},
          db: mockFirestore,
          auth: mockAuth,
          isBeingTested: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('descriptionPage'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    await tester.pumpAndSettle(const Duration(seconds: 5));
    
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('descriptionPage2'), findsOneWidget);
  });


}