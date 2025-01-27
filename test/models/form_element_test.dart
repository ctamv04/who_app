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
}