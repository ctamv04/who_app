import 'dart:convert';

import 'form_element.dart';

class Page {

  String _title;
  String? _description;
  int _pageNumber;
  List<FormElement>? _elements;

  Page({
    required String title,
    required int pageNumber,
    String? description,
    List<FormElement>? elements
  }) : _title = title, _pageNumber = pageNumber, _description = description ?? "", _elements = elements ?? <FormElement>[];

  factory Page.fromJson(Map<String, dynamic> json) {

    List<FormElement> elements = [];
    for(Map<String, dynamic> a in json['elements']){
      elements.add(FormElement.fromJson(a));
    }

    return Page(
      title: json['title'] as String,
      pageNumber: json['page_number'] as int,
      description: json['description'] as String,
      elements: elements
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'title': _title,
        'page_number': _pageNumber,
        'description': _description,
        'elements': _elements?.map((x) => x.toJson()).toList()
      };

  String get title => _title;
  int get pageNumber => _pageNumber;
  String? get description => _description;
  List<FormElement>? get elements => _elements;
}