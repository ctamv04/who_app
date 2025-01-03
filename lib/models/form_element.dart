import 'package:who_app/models/selection.dart';
import 'package:who_app/models/text.dart';

abstract class FormElement {

  String _title;
  String _subTitle;
  int _index;
  bool _required;

  FormElement({
    required String title,
    String? subTitle,
    required int index,
    bool? required
  }) : _title = title, _subTitle = subTitle ?? "", _index = index, _required = required ?? false;

  factory FormElement.fromJson(Map<String, dynamic> json) {

    var type = json['type'] as String;
    if(type == "text"){
      return Text.fromJson(json);
    }else{
      return Selection.fromJson(json);
    }
  }

  void toJson();

  String get title => _title;
  String get subTitle => _subTitle;
  int get index => _index;
  bool get required => _required;
}