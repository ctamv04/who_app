import 'package:who_app/models/page.dart';

import 'form_element.dart';

class FieldPage extends Page {

  Map<int, FormElement>? _elements;

  FieldPage({
    required super.title,
    super.description,
    Map<int, FormElement>? elements
  }) : _elements = elements ?? {};

  factory FieldPage.fromJson(Map<String, dynamic> json) {

    return FieldPage(
      title: json['title'] as String,
      description: json['description'] as String,
      elements: (json['elements'] as Map<String, dynamic>).map((k,v) => MapEntry(int.parse(k), FormElement.fromJson(v)))
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {
        'title': super.title,
        'description': super.description,
        'elements': _elements?.map((k,v) => MapEntry(k.toString(), v.toJson()))
      };

  Map<int, FormElement>? get elements => _elements;
}