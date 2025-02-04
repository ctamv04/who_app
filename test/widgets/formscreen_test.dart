import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/screens/form_screen.dart';
import 'package:who_app/models/form.dart' as form_model;
import 'package:who_app/models/page.dart' as page_model;
import 'package:who_app/models/text.dart' as text_model;
import 'package:who_app/models/selection.dart' as selection_model;
import 'package:who_app/models/location.dart' as location_model;
import 'package:who_app/models/image_element.dart' as image_model;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';


class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUp(() async {
    mockFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
  });

  testWidgets('FormScreen renders with form data', (WidgetTester tester) async {
    final page = page_model.Page(
      title: "Page 1", 
      description: "descriptionPage", 
      elements: {
        0: text_model.Text(
          title: "Text Title", 
          subTitle: "Text Subtitle", 
          required: false, 
          text: ""
        ),
        1: selection_model.Selection(
          title: "Selection Title",
          subTitle: "Selection Subtitle",
          selections: {"Option 1": false, "Option 2": true, "other": false},
        ),
        2: location_model.Location(
          title: "Location Title",
          subTitle: "Location Subtitle",
        ),
        3: image_model.ImagePickerElement(
          title: "ImagePicker Title",
          subTitle: "ImagePicker Subtitle",
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

  await tester.pump();

  expect(find.text('Page 1'), findsOneWidget);
  expect(find.text('descriptionPage'), findsOneWidget);

  expect(find.text('Text Title'), findsOneWidget);
  expect(find.text('Text Subtitle'), findsOneWidget);

  expect(find.text('Selection Title'), findsOneWidget);
  expect(find.text('Selection Subtitle'), findsOneWidget);

  expect(find.text('Location Title'), findsOneWidget);
  expect(find.text('Location Subtitle'), findsOneWidget);

  expect(find.text('ImagePicker Title'), findsOneWidget);
  expect(find.text('ImagePicker Subtitle'), findsOneWidget);
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