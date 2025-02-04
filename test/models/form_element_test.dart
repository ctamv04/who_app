import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:who_app/models/location.dart';
import 'package:who_app/models/text.dart';
import 'package:who_app/models/selection.dart';
import 'package:who_app/models/form_element.dart';

void main() {
  final textJson = {
    'type': 'text',
    'title': 'Test Title',
    'subtitle': 'Test Subtitle',
    'required': true,
    'text': 'Sample text',
  };

  final selectionJson = {
    'type': 'selection',
    'title': 'Test Title',
    'subtitle': 'Test Subtitle',
    'required': false,
    'num_selections': 3,
    'other': true,
    'selections': {'Option 1': true, 'Option 2': false},
    'other_text': 'Other option text',
  };

  final locationJson = {
    'type': 'location',
    'title': 'Location Title',
    'subtitle': 'Location Subtitle',
    'required': true,
    'address': '123 Main St',
    'coordinates': {'lat': 40.7128, 'long': -74.0060},
  };


  test('FormElement.fromJson creates the correct subclass instance', () {
  // Text
  final textElement = FormElement.fromJson(textJson);
  expect(textElement, isA<Text>());
  expect((textElement as Text).text, 'Sample text');

  // Selection
  final selectionElement = FormElement.fromJson(selectionJson);
  expect(selectionElement, isA<Selection>());
  expect((selectionElement as Selection).selections['Option 1'], isTrue);

  // Location
  final locationElement = FormElement.fromJson(locationJson);
  expect(locationElement, isA<Location>());
  expect((locationElement as Location).address, '123 Main St');
});

test('FormElement properties are inherited correctly in Text', () {
  final textElement = Text(
    title: 'Test Title',
    subTitle: 'Test Subtitle',
    required: true,
    text: 'Sample text',
  );

  expect(textElement.title, 'Test Title');
  expect(textElement.subTitle, 'Test Subtitle');
  expect(textElement.required, isTrue);
  expect(textElement.text, 'Sample text');
});

test('FormElement properties are inherited correctly in Selection', () {
    final selectionElement = Selection(
      title: 'Test Title',
      subTitle: 'Test Subtitle',
      required: false,
      selections: {'Option 1': true, 'Option 2': false},
      numSelections: 3,
      other: true,
      otherText: 'Other option text',
    );

    expect(selectionElement.title, 'Test Title');
    expect(selectionElement.subTitle, 'Test Subtitle');
    expect(selectionElement.required, isFalse);
    expect(selectionElement.numSelections, 3);
    expect(selectionElement.other, isTrue);
    expect(selectionElement.otherText, 'Other option text');
    expect(selectionElement.selections['Option 1'], isTrue);
  });

  test('FormElement properties are inherited correctly in Location', () {
    final locationElement = Location(
      title: 'Location Title',
      subTitle: 'Location Subtitle',
      required: true,
      address: '123 Main St',
      coordinates: LatLng(40.7128, -74.0060),
    );

    expect(locationElement.title, 'Location Title');
    expect(locationElement.subTitle, 'Location Subtitle');
    expect(locationElement.required, isTrue);
    expect(locationElement.address, '123 Main St');
    expect(locationElement.coordinates.latitude, 40.7128);
    expect(locationElement.coordinates.longitude, -74.0060);
  });

  test('Text toJson correctly serializes to JSON', () {
    final textElement = Text(
      title: 'Test Title',
      subTitle: 'Test Subtitle',
      required: true,
      text: 'Sample text',
    );

    final json = textElement.toJson();
    expect(json['type'], 'text');
    expect(json['title'], 'Test Title');
    expect(json['subtitle'], 'Test Subtitle');
    expect(json['required'], true);
    expect(json['text'], 'Sample text');
    expect(json['special'], '');
  });

  test('Selection toJson correctly serializes to JSON', () {
    final selectionElement = Selection(
      title: 'Test Title',
      subTitle: 'Test Subtitle',
      required: false,
      selections: {'Option 1': true, 'Option 2': false},
      numSelections: 3,
      other: true,
      otherText: 'Other option text',
    );

    final json = selectionElement.toJson();
    expect(json['type'], 'selection');
    expect(json['title'], 'Test Title');
    expect(json['subtitle'], 'Test Subtitle');
    expect(json['required'], false);
    expect(json['num_selections'], 3);
    expect(json['other'], true);
    expect(json['selections'], {'Option 1': true, 'Option 2': false});
    expect(json['other_text'], 'Other option text');
  });

  test('Location toJson correctly serializes to JSON', () {
    final locationElement = Location(
      title: 'Location Title',
      subTitle: 'Location Subtitle',
      required: true,
      address: '123 Main St',
      coordinates: LatLng(40.7128, -74.0060),
    );

    final json = locationElement.toJson();
    expect(json['type'], 'location');
    expect(json['title'], 'Location Title');
    expect(json['subtitle'], 'Location Subtitle');
    expect(json['required'], true);
    expect(json['address'], '123 Main St');
    expect(json['coordinates']['lat'], 40.7128);
    expect(json['coordinates']['long'], -74.0060);
  });

  test('Text.fromJson correctly creates an instance from JSON', () {
    final textElement = Text.fromJson(textJson);

    expect(textElement.title, 'Test Title');
    expect(textElement.subTitle, 'Test Subtitle');
    expect(textElement.required, isTrue);
    expect(textElement.text, 'Sample text');
  });

  test('Selection.fromJson correctly creates an instance from JSON', () {
    final selectionElement = Selection.fromJson(selectionJson);

    expect(selectionElement.title, 'Test Title');
    expect(selectionElement.subTitle, 'Test Subtitle');
    expect(selectionElement.required, isFalse);
    expect(selectionElement.numSelections, 3);
    expect(selectionElement.other, isTrue);
    expect(selectionElement.otherText, 'Other option text');
    expect(selectionElement.selections['Option 1'], isTrue);
  });

  test('Location.fromJson correctly creates an instance from JSON', () {
    final locationElement = Location.fromJson(locationJson);

    expect(locationElement.title, 'Location Title');
    expect(locationElement.subTitle, 'Location Subtitle');
    expect(locationElement.required, isTrue);
    expect(locationElement.address, '123 Main St');
    expect(locationElement.coordinates.latitude, 40.7128);
    expect(locationElement.coordinates.longitude, -74.0060);
  });

  test('FormElement handles invalid type gracefully', () {
    final invalidJson = {
      'type': 'invalid_type',
      'title': 'Test Title',
      'subtitle': 'Test Subtitle',
      'required': true,
    };

    final formElement = FormElement.fromJson(invalidJson);
    expect(formElement, isA<Location>());
  });

  test('Selection handles default values correctly when optional fields are missing', () {
    final selectionJsonWithoutOptionalFields = {
      'type': 'selection',
      'title': 'Test Title',
      'subtitle': 'Test Subtitle',
      'required': false,
      'selections': {'Option 1': true},
    };

    final selectionElement = Selection.fromJson(selectionJsonWithoutOptionalFields);

    expect(selectionElement.numSelections, 1);
    expect(selectionElement.other, isFalse);
    expect(selectionElement.otherText, '');
  });


}