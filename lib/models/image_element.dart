import 'dart:convert';
import 'dart:io'; 
import 'package:who_app/models/form_element.dart';
import 'package:who_app/models/page.dart';

class ImagePickerElement extends FormElement {
  List<File> imageFiles;
  List<String> fileNames;
  List<String?> downloadUrls;

  ImagePickerElement({
    required String title,
    List<File>? imageFiles,
    List<String>? fileNames,
    List<String?>? downloadUrls,
    String subTitle = "",
  }) : imageFiles = imageFiles ?? [], fileNames = fileNames ?? [], downloadUrls = downloadUrls ?? [], super(title: title, subTitle: subTitle);

  void addImage(File file) {
    imageFiles.add(file);
    downloadUrls.add(null);
  }

  void removeImage(int index) {
    imageFiles.removeAt(index);
    downloadUrls.removeAt(index);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': 'image_picker',
      'subTitle': subTitle, 
      'fileNames': fileNames,
      'downloadUrls': downloadUrls,
    };
  }

  factory ImagePickerElement.fromJson(Map<String, dynamic> json) {
    return ImagePickerElement(
      title: json['title'] as String? ?? 'Untitled',
      subTitle: json['subTitle'] as String? ?? "",
      fileNames: (json['fileNames'] as List<dynamic>?) 
          ?.map((e) => e as String)
          .toList() ?? [],
      downloadUrls: (json['downloadUrls'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList() ?? [],
    );
  }
}
