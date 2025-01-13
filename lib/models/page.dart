import 'field_page.dart';
import 'location_page.dart';

abstract class Page {

  String _title;
  String _description;

  Page({
    required String title,
    String? description,
  }) : _title = title, _description = description ?? "";

  factory Page.fromJson(Map<String, dynamic> json) {

    var type = (json['type'] ?? "") as String;
    if(type == "location"){
      return LocationPage.fromJson(json);
    }else{
      return FieldPage.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();

  String get title => _title;
  String get description => _description;
}