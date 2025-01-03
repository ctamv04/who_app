import 'dart:convert';

import 'form_element.dart';

class Selection extends FormElement {

  List<String> _options;
  int _numOptions;
  bool _other;
  Set<String> _selections;
  String? _otherText;

  Selection({
    required super.title,
    super.subTitle,
    required super.index,
    super.required,
    List<String>? options,
    int? numOptions,
    bool? other,
    Set<String>? selections,
    String? otherText
  }) : _options = options ?? <String>[],
        _numOptions = (numOptions != null && numOptions > 0) ? numOptions : 1,
        _other = other ?? false,
        _selections = selections ?? <String>{},
        _otherText = otherText ?? "";

  factory Selection.fromJson(Map<String, dynamic> json) {

    return Selection(
      title: json['title'] as String,
      subTitle: json['subtitle'] as String,
      index: json['index'] as int,
      required: json['required'] as bool,
      options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      numOptions: json['num_options'] as int,
      other: json['other'] as bool,
      selections: (json['selections'] as List<dynamic>).map((e) => e as String).toSet(),
      otherText: json['other_text'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {
        'title': super.title,
        'subtitle': super.subTitle,
        'index': super.index,
        'required': super.required,
        'type': "selection",
        'options': _options,
        'num_options': _numOptions,
        'other': _other,
        'selections': _selections.toList(),
        'other_text': _otherText
      };

  List<String> get options => _options;
  int get numOptions => _numOptions;
  bool get other => _other;
  Set<String> get selections => _selections;
  String? get otherText => _otherText;
}