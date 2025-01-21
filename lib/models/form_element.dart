import 'package:who_app/models/selection.dart';
import 'package:who_app/models/text.dart';
import 'location.dart';

abstract class FormElement {

  String _title;
  String _subTitle;
  bool _required;

  FormElement({
    required String title,
    String? subTitle,
    bool? required
  }) : _title = title, _subTitle = subTitle ?? "", _required = required ?? false;

  factory FormElement.fromJson(Map<String, dynamic> json) {

    var type = json['type'] as String;
    if(type == "text"){
      return Text.fromJson(json);
    }else if(type == "selection"){
      return Selection.fromJson(json);
    }else{
      return Location.fromJson(json);
    }
  }

  void toJson();

  String get title => _title;
  String get subTitle => _subTitle;
  bool get required => _required;
}