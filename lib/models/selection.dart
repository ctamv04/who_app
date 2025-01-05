import 'form_element.dart';

class Selection extends FormElement {

  List<String> _options;
  int _numSelections;
  bool _other;
  Set<String> _selections;
  String? _otherText;

  Selection({
    required super.title,
    super.subTitle,
    super.required,
    List<String>? options,
    int? numSelections,
    bool? other,
    Set<String>? selections,
    String? otherText
  }) : _options = options ?? <String>[],
        _numSelections = (numSelections != null && numSelections > 0) ? numSelections : 1,
        _other = other ?? false,
        _selections = selections ?? <String>{},
        _otherText = otherText ?? "";

  factory Selection.fromJson(Map<String, dynamic> json) {

    return Selection(
      title: json['title'] as String,
      subTitle: json['subtitle'] as String,
      required: json['required'] as bool,
      options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      numSelections: json['num_selections'] as int?,
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
        'required': super.required,
        'type': "selection",
        'options': _options,
        'num_selections': _numSelections,
        'other': _other,
        'selections': _selections.toList(),
        'other_text': _otherText
      };

  List<String> get options => _options;
  int get numSelections => _numSelections;
  bool get other => _other;
  Set<String> get selections => _selections;
  String? get otherText => _otherText;
}