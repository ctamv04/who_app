import 'form_element.dart';

class Selection extends FormElement {

  int _numSelections;
  bool _other;
  Map<String, bool> _selections;
  String _otherText;

  Selection({
    required super.title,
    super.subTitle,
    super.required,
    required Map<String, bool> selections,
    int? numSelections,
    bool? other,
    String? otherText
  }) : _numSelections = (numSelections != null && numSelections > 0) ? numSelections : 1,
        _other = other ?? false,
        _selections = ((other ?? false) && (selections["other"] == null)) ? (selections..["other"] = false) : selections,
        _otherText = ((other ?? false) && otherText != null || (selections["other"] ?? false)) ? (otherText ?? "") : "";

  factory Selection.fromJson(Map<String, dynamic> json) {

    return Selection(
      title: json['title'] as String? ?? "",
      subTitle: json['subtitle'] as String? ?? "",
      required: json['required'] as bool? ?? false,
      numSelections: json['num_selections'] as int? ?? 1,
      other: json['other'] as bool? ?? false,
      selections: (json['selections'] as Map<String, dynamic>).map((k,v) => MapEntry(k, v as bool)),
      otherText: json['other_text'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {
        'title': super.title,
        'subtitle': super.subTitle,
        'required': super.required,
        'type': "selection",
        'num_selections': _numSelections,
        'other': _other,
        'selections': _selections,
        'other_text': _otherText
      };

  int get numSelections => _numSelections;
  bool get other => _other;
  Map<String, bool> get selections => _selections;
  String? get otherText => _otherText;

  set otherText(String? otherText) => _otherText = (_other && otherText != null || (_selections["other"] ?? false)) ? (otherText ?? "") : "";
  set selections(Map<String, bool> selections) => _selections = (_other && (selections["other"] == null)) ? (selections..["other"] = false) : selections;
}