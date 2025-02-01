import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:who_app/models/form_element.dart';
import 'package:who_app/models/page.dart';

class ImagePickerElement extends FormElement {
  List<Uint8List> imageFiles;
  List<String> fileNames;
  List<String?> downloadUrls;

  ImagePickerElement({
    required super.title,
    super.subTitle,
    super.required,
    List<Uint8List>? imageFiles,
    List<String>? fileNames,
    List<String?>? downloadUrls,
  }) : imageFiles = imageFiles ?? [], fileNames = fileNames ?? [], downloadUrls = downloadUrls ?? [];

  void addImage(Uint8List image) {
    imageFiles.add(image);
    downloadUrls.add(null);
  }

  void removeImage(int index) {
    imageFiles.removeAt(index);
    downloadUrls.removeAt(index);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': super.title,
      'subtitle': super.subTitle,
      'required': super.required,
      'type': 'image_picker',
      'fileNames': fileNames,
      'downloadUrls': downloadUrls,
    };
  }

  factory ImagePickerElement.fromJson(Map<String, dynamic> json) {
    return ImagePickerElement(
      title: json['title'] as String,
      subTitle: json['subtitle'] as String,
      required: json['required'] as bool,
      fileNames: (json['fileNames'] as List<dynamic>?) 
          ?.map((e) => e as String)
          .toList() ?? [],
      downloadUrls: (json['downloadUrls'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList() ?? [],
    );
  }
}
