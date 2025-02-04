import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:who_app/screens/form_screen_readonly.dart'; 
import 'package:who_app/models/page.dart' as page_model;
import 'package:who_app/models/text.dart' as text_model;

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockNetworkImage extends Mock implements ImageProvider {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
  });

  testWidgets('FormScreenReadOnly displays elements correctly', (tester) async {
    final form = {
      'pages': {
        '1': page_model.Page(
          title: 'Test Page',
          description: 'This is a test page description.',
          elements: {
            1: text_model.Text(title: 'Test Element', subTitle: 'Subtitle', required: true, text: 'Sample Text')
          },
        ).toJson(),
      }
    };

    final computedPages = {
      1: page_model.Page.fromJson(form['pages']?['1'] ?? {}),
    };

    await tester.pumpWidget(MaterialApp(
      home: FormScreenReadOnly(
        form: form,
        pageNumber: 1,
        computedPages: computedPages,
        db: mockFirestore,
        auth: mockAuth,
      ),
    ));

    await tester.pump();

    expect(find.text('Test Page'), findsOneWidget);
    expect(find.text('This is a test page description.'), findsOneWidget);

    expect(find.text('Test Element'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.text('Sample Text'), findsOneWidget);  
  });

  testWidgets('FormScreenReadOnly navigates between pages correctly', (tester) async {
    final form = {
      'pages': {
        '1': {
          'title': 'Page 1',
          'description': 'Description for page 1.',
          'elements': {
            '1': {'type': 'text', 'title': 'Element 1', 'subTitle': 'Subtitle', 'required': true}
          }
        },
        '2': {
          'title': 'Page 2',
          'description': 'Description for page 2.',
          'elements': {
            '1': {'type': 'text', 'title': 'Element 2', 'subTitle': 'Subtitle', 'required': true}
          }
        }
      }
    };

    final computedPages = {
        1: page_model.Page.fromJson(form['pages']?['1'] ?? {}),
        2: page_model.Page.fromJson(form['pages']?['2'] ?? {}),
    };

    await tester.pumpWidget(MaterialApp(
      home: FormScreenReadOnly(
        form: form,
        pageNumber: 1,
        computedPages: computedPages,
        db: mockFirestore,
        auth: mockAuth,
      ),
    ));

    await tester.pump();

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Description for page 1.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Description for page 2.'), findsOneWidget);
  });

  testWidgets('FormScreenReadOnly displays text elements correctly', (tester) async {
  final form = {
    'pages': {
      '1': {
        'title': 'Test Page with Text Field',
        'description': 'This page contains a text field.',
        'elements': {
          '1': {
            'type': 'text',
            'title': 'Text Field',
            'subTitle': 'A test text field',
            'required': true,
            'text': 'Sample text value'
          }
        }
      }
    }
  };

  final computedPages = {
        1: page_model.Page.fromJson(form['pages']?['1'] ?? {}),
  };

  await tester.pumpWidget(MaterialApp(
    home: FormScreenReadOnly(
      form: form,
      pageNumber: 1,
      computedPages: computedPages,
      db: mockFirestore,
      auth: mockAuth,
    ),
  ));

  await tester.pump();

  expect(find.byType(TextFormField), findsOneWidget);
  expect(find.text('Sample text value'), findsOneWidget);
});

testWidgets('FormScreenReadOnly displays selection elements correctly', (tester) async {
  final form = {
    'pages': {
      '1': {
        'title': 'Test Page with Selection',
        'description': 'This page contains selection elements.',
        'elements': {
          '1': {
            'type': 'selection',
            'title': 'Selection Element',
            'subTitle': 'Choose an option',
            'required': true,
            'selections': {
              'Option 1': true,
              'Option 2': false,
              'other': false,
            },
            'numSelections': 1
          }
        }
      }
    }
  };

  final computedPages = {
        1: page_model.Page.fromJson(form['pages']?['1'] ?? {}),
  };

  await tester.pumpWidget(MaterialApp(
    home: FormScreenReadOnly(
      form: form,
      pageNumber: 1,
      computedPages: computedPages,
      db: mockFirestore,
      auth: mockAuth,
    ),
  ));

  await tester.pumpAndSettle;

  expect(find.text('Selection Element'), findsOneWidget);
  expect(find.byType(RadioListTile<String>), findsNWidgets(2));
  expect(find.text('Option 1'), findsOneWidget);
  expect(find.text('Option 2'), findsOneWidget);
});

testWidgets('FormScreenReadOnly handles empty selection elements correctly', (tester) async {
  final form = {
    'pages': {
      '1': {
        'title': 'Test Page with Empty Selection',
        'description': 'This page contains an empty selection element.',
        'elements': {
          '1': {
            'type': 'selection',
            'title': 'Selection Element',
            'subTitle': 'Choose an option',
            'required': true,
            'selections': {
              'Option 1': false,
              'Option 2': false,
              'other': false,
            },
            'numSelections': 1
          }
        }
      }
    }
  };

  final computedPages = {
        1: page_model.Page.fromJson(form['pages']?['1'] ?? {}),
  };

  await tester.pumpWidget(MaterialApp(
    home: FormScreenReadOnly(
      form: form,
      pageNumber: 1,
      computedPages: computedPages,
      db: mockFirestore,
      auth: mockAuth,
    ),
  ));

  await tester.pump();

  expect(find.byType(RadioListTile<String>), findsNWidgets(2)); 
});

}
