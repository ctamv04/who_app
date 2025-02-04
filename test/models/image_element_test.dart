import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/models/form.dart';
import 'package:who_app/models/image_element.dart';
import 'package:who_app/models/page.dart';
import 'package:who_app/models/form_element.dart';

void main(){
  test('Constructor initializes with default values', () {
    final element = ImagePickerElement(
      title: 'Test Image Picker',
      subTitle: 'Test subtitle',
      required: true,
    );

    expect(element.title, 'Test Image Picker');
    expect(element.subTitle, 'Test subtitle');
    expect(element.required, true);
    expect(element.imageFiles, isEmpty);
    expect(element.fileNames, isEmpty);
    expect(element.downloadUrls, isEmpty);
  });

  test('addImage adds an image correctly', () {
    final element = ImagePickerElement(
      title: 'Test Image Picker',
      subTitle: 'Test subtitle',
      required: true,
    );
    final image = Uint8List.fromList([1, 2, 3, 4, 5]);

    element.addImage(image);

    expect(element.imageFiles, hasLength(1));
    expect(element.imageFiles.first, image);
    expect(element.downloadUrls, hasLength(1));
    expect(element.downloadUrls.first, null); 
  });

  test('removeImage removes an image correctly', () {
    final element = ImagePickerElement(
      title: 'Test Image Picker',
      subTitle: 'Test subtitle',
      required: true,
    );
    final image = Uint8List.fromList([1, 2, 3, 4, 5]);

    element.addImage(image);
    expect(element.imageFiles, hasLength(1));

    element.removeImage(0);
    expect(element.imageFiles, isEmpty);
    expect(element.downloadUrls, isEmpty);
  });

  test('toJson returns correct JSON representation', () {
    final element = ImagePickerElement(
      title: 'Test Image Picker',
      subTitle: 'Test subtitle',
      required: true,
      fileNames: ['file1.jpg', 'file2.jpg'],
      downloadUrls: ['url1', 'url2'],
    );

    final json = element.toJson();

    expect(json['title'], 'Test Image Picker');
    expect(json['subtitle'], 'Test subtitle');
    expect(json['required'], true);
    expect(json['fileNames'], ['file1.jpg', 'file2.jpg']);
    expect(json['downloadUrls'], ['url1', 'url2']);
    expect(json['type'], 'image_picker');
  });

  test('fromJson creates an ImagePickerElement correctly', () {
    final json = {
      'title': 'Test Image Picker',
      'subtitle': 'Test subtitle',
      'required': true,
      'fileNames': ['file1.jpg', 'file2.jpg'],
      'downloadUrls': ['url1', 'url2'],
      'type': 'image_picker',
    };

    final element = ImagePickerElement.fromJson(json);

    expect(element.title, 'Test Image Picker');
    expect(element.subTitle, 'Test subtitle');
    expect(element.required, true);
    expect(element.fileNames, ['file1.jpg', 'file2.jpg']);
    expect(element.downloadUrls, ['url1', 'url2']);
  });
}