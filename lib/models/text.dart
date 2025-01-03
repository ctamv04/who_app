import 'form_element.dart';

class Text extends FormElement {

  String _text;

  Text({
    required super.title,
    super.subTitle,
    required super.index,
    super.required,
    String? text
  }) : _text = text ?? "";

  factory Text.fromJson(Map<String, dynamic> json) {

    return Text(
      title: json['title'] as String,
      subTitle: json['subtitle'] as String,
      index: json['index'] as int,
      required: json['required'] as bool,
      text: json['text'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {
        'title': super.title,
        'subtitle': super.subTitle,
        'index': super.index,
        'required': super.required,
        'type': "text",
        'text': _text
      };

  String get text => _text;
}