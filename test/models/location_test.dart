import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:who_app/models/location.dart';

void main() {
    const testTitle = "Test Location";
    const testSubTitle = "Test Subtitle";
    const testRequired = false;
    const testAddress = "123 Test Street";
    final testCoordinates = LatLng(12.34, 56.78);

    test('Location can be initialized correctly', () {
      final locationElement = Location(
        title: testTitle,
        subTitle: testSubTitle,
        required: testRequired,
        address: testAddress,
        coordinates: testCoordinates,
      );

      expect(locationElement.title, testTitle);
      expect(locationElement.subTitle, testSubTitle);
      expect(locationElement.required, testRequired);
      expect(locationElement.address, testAddress);
      expect(locationElement.coordinates, testCoordinates);
    });

    test('Location.fromJson() creates correct object', () {
      final json = {
        'title': testTitle,
        'subtitle': testSubTitle,
        'required': testRequired,
        'type': "location",
        'address': testAddress,
        'coordinates': {'lat': 12.34, 'long': 56.78},
      };

      final locationElement = Location.fromJson(json);

      expect(locationElement.title, testTitle);
      expect(locationElement.subTitle, testSubTitle);
      expect(locationElement.required, testRequired);
      expect(locationElement.address, testAddress);
      expect(locationElement.coordinates, testCoordinates);
    });

    test('Location.toJson() returns correct JSON', () {
      final locationElement = Location(
        title: testTitle,
        subTitle: testSubTitle,
        required: testRequired,
        address: testAddress,
        coordinates: testCoordinates,
      );

      final json = locationElement.toJson();

      expect(json['title'], testTitle);
      expect(json['subtitle'], testSubTitle);
      expect(json['required'], testRequired);
      expect(json['type'], "location");
      expect(json['address'], testAddress);
      expect(json['coordinates']['lat'], testCoordinates.latitude);
      expect(json['coordinates']['long'], testCoordinates.longitude);
    });

    test('Location getter and setter work correctly', () {
      final locationElement = Location(
        title: testTitle,
        subTitle: testSubTitle,
        required: testRequired,
        address: testAddress,
        coordinates: testCoordinates,
      );

      // Testen der Getter
      expect(locationElement.address, testAddress);
      expect(locationElement.coordinates, testCoordinates);

      // Testen der Setter
      locationElement.address = 'New Test Address';
      locationElement.coordinates = LatLng(47.0, 8.0);

      expect(locationElement.address, 'New Test Address');
      expect(locationElement.coordinates, LatLng(47.0, 8.0));
    });
}