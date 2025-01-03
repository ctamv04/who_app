import 'dart:convert';

import 'form_element.dart';

class Page {

  String _title;
  String _description;
  int _pageNumber;
  Map<int, FormElement>? _elements;

  Page({
    required String title,
    required int pageNumber,
    String? description,
    Map<int, FormElement>? elements
  }) : _title = title, _pageNumber = pageNumber, _description = description ?? "", _elements = elements ?? {};

  factory Page.fromJson(Map<String, dynamic> json) {

    return Page(
      title: json['title'] as String,
      pageNumber: json['page_number'] as int,
      description: json['description'] as String,
      elements: (json['elements'] as Map<String, dynamic>).map((k,v) => MapEntry(int.parse(k), FormElement.fromJson(v)))
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'title': _title,
        'page_number': _pageNumber,
        'description': _description,
        'elements': _elements?.map((k,v) => MapEntry(k.toString(), v.toJson()))
      };

  String get title => _title;
  int get pageNumber => _pageNumber;
  String get description => _description;
  Map<int, FormElement>? get elements => _elements;
}