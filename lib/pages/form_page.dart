import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/form.dart' as form_model;
import '../models/form_element.dart';
import '../models/page.dart' as page_model;
import '../models/selection.dart';
import '../models/text.dart' as text_model;

class FormPage extends StatefulWidget {

  FormPage({
    super.key,
    required Map<String, dynamic>? form,
    required int pageNumber,
    page_model.Page? page,
    required FirebaseFirestore db
  }) : _form = form,
        _pageNumber = pageNumber,
        _page = page ?? page_model.Page.fromJson((form?['pages'] as List).where((x) => x['page_number'] == pageNumber).first),
        _db = db;

  final page_model.Page? _page;

  final int _pageNumber;

  final Map<String, dynamic>? _form;

  final FirebaseFirestore _db;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {

  final _formKey = GlobalKey<FormState>();

  final Map<int, String?> radioSelections = {};

  final Map<int, Map<String, bool>?> checkboxSelections = {};

  final Map<int, TextEditingController> controllers = {};

  @override
  void dispose() {

    for(TextEditingController controller in controllers.values){
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget._page!.title),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: widget._page!.elements!.map((x) => makeWidget(x)).toList()
        ),
      ),
    );
  }

  Widget makeWidget(FormElement element){

    if(element.runtimeType == text_model.Text){

      text_model.Text textElement = element as text_model.Text;
      controllers[textElement.index] = TextEditingController();

      return TextFormField(
        decoration: InputDecoration(
          hintText: textElement.subTitle,
          labelText: textElement.title,
        ),
        controller: controllers[textElement.index],
      );
    }else if(element.runtimeType == Selection){

      Selection selElement = element as Selection;
      List<Widget> seList = [];
      if(selElement.numOptions == 1){

        radioSelections[selElement.index] = selElement.otherText!.isNotEmpty ? "other" : selElement.selections.first;

        seList = selElement.options.map((x) {
          RadioListTile<String>(
            title: Text(x),
            value: x,
            groupValue: radioSelections[selElement.index],
            onChanged: (String? value) {
              setState(() {
                radioSelections[selElement.index] = value;
              });
            },
          );
        }).toList() as List<Widget>;

        if(selElement.other){

          controllers[selElement.index] = TextEditingController();

          seList.add(
              RadioListTile<String>(
                title: TextFormField(
                  decoration: InputDecoration(
                    labelText: selElement.otherText,
                  ),
                  controller: controllers[selElement.index],
                ),
                value: "other",
                groupValue: radioSelections[selElement.index],
                onChanged: (String? value) {
                  setState(() {
                    radioSelections[selElement.index] = "other";
                  });
                },
              )
          );
        }
      }else{

        // seList = selElement.options.map((x) {
        //   CheckboxListTile(
        //     title: new Text(key),
        //     value: values[key],
        //     onChanged: (bool value) {
        //       setState(() {
        //         values[key] = value;
        //       });
        //     },
        //   );
        // }).toList() as List<Widget>;
      }

      return Column(
        children: seList,
      );
    }
  }
}