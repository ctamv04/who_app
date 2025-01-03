import 'dart:convert';

import 'package:who_app/models/page.dart';

class Form {

  String _title;
  String _description;
  List<Page> _pages;

  Form({
    required String title,
    String? description,
    List<Page>? pages
  }) : _title = title, _description = description ?? "", _pages = pages ?? <Page>[];

  factory Form.fromJson(Map<String, dynamic> json) {

    return Form(
        title: json['title'] as String,
        description: json['description'] as String,
        pages: (json['pages'] as List).map((x) => Page.fromJson(x)).toList()
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'title': _title,
        'description': _description,
        'pages': _pages.map((x) => x.toJson()).toList()
      };
}