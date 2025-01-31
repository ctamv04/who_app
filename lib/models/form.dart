import 'dart:convert';

import 'package:who_app/models/page.dart';

class Form {

  String _title;
  String _description;
  Map<int, Page> _pages;

  Form({
    required String title,
    String? description,    
    Map<int, Page>? pages,
    
  }) : _title = title, _description = description ?? "", _pages = pages ?? {};

  factory Form.fromJson(Map<String, dynamic> json) {

    return Form(
        title: json['title'] as String,
        description: json['description'] as String,
        pages: (json['pages'] as Map<String, dynamic>).map((k,v) => MapEntry(int.parse(k), Page.fromJson(v))),
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'title': _title,
        'description': _description,
        'pages': _pages.map((k,v) => MapEntry(k.toString(), v.toJson())),
      };
}