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
        _page = page ?? page_model.Page.fromJson(form?['pages'][pageNumber.toString()]),
        _db = db;

  final page_model.Page _page;

  final int _pageNumber;

  final Map<String, dynamic>? _form;

  final FirebaseFirestore _db;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {

  final _formKey = GlobalKey<FormState>();

  final Map<int, String?> _radioSelections = {};

  final Map<int, Map<String, bool>?> _checkboxSelections = {};

  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {

    for(TextEditingController controller in _controllers.values){
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> seList = [];
    if(widget._page.description.isNotEmpty){
      seList += [
        Text(widget._page.description,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        Divider(
          color: Colors.black,
          thickness: 1,
        ),
        SizedBox(height: 30)
      ];
    }
    seList += widget._page!.elements!.map((k,v) => MapEntry(k, makeWidget(k, v))).values.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget._page!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Next page',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormPage(
                      form: widget._form,
                      pageNumber: widget._pageNumber + 1,
                      db: widget._db
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: seList
          ),
        ),
      ),
    );
  }

  Widget makeWidget(int index, FormElement element){

    List<Widget> seList = [
      Text(element.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      Text(element.subTitle,
        style: TextStyle(
          fontSize: 18,
        ),
      ),
    ];

    if(element.runtimeType == text_model.Text){

      if(_controllers[index] == null){
        _controllers[index] = TextEditingController();
      }

      seList.add(TextFormField(
        decoration: InputDecoration(
          hintText: "Your answer",
        ),
        controller: _controllers[index],
      ));

    }else if(element.runtimeType == Selection){

      Selection selElement = element as Selection;

      if(selElement.numSelections == 1){

        if(_radioSelections[index] == null){
          _radioSelections[index] = selElement.selections.isNotEmpty ? selElement.selections.first : "";
        }

        seList += selElement.options.map((x) {
          return RadioListTile<String>(
            title: Text(x),
            value: x,
            groupValue: _radioSelections[index],
            contentPadding: EdgeInsets.only(bottom: 1.0),
            onChanged: (String? value) {
              setState(() {
                _radioSelections[index] = value;
              });
            },
          );
        }).toList() as List<Widget>;

        if(selElement.other){

          if(_controllers[index] == null){
            _controllers[index] = TextEditingController();
          }

          seList.add(
              RadioListTile<String>(
                title: TextFormField(
                  decoration: InputDecoration(
                    labelText: selElement.otherText,
                  ),
                  controller: _controllers[index],
                ),
                value: "other",
                groupValue: _radioSelections[index],
                contentPadding: EdgeInsets.only(bottom: 1.0),
                onChanged: (String? value) {
                  setState(() {
                    _radioSelections[index] = "other";
                  });
                },
              )
          );
        }
      }else{

        if(_checkboxSelections[index] == null){
          _checkboxSelections[index] = { for (var v in selElement.options) v: selElement.selections.contains(v) };
        }

        seList += selElement.options.map((x) {
          return CheckboxListTile(
            title: Text(x),
            value: _checkboxSelections[index]?[x],
            contentPadding: EdgeInsets.only(bottom: 1.0),
            onChanged: (bool? value) {
              setState(() {
                _checkboxSelections[index]?[x] = value!;
              });
            },
          );
        }).toList() as List<Widget>;

        if(selElement.other){

          if(_controllers[index] == null){
            _controllers[index] = TextEditingController();
          }
          if(_checkboxSelections[index]?["other"] == null){
            _checkboxSelections[index]?["other"] = selElement.otherText!.isNotEmpty;
          }

          seList.add(
            CheckboxListTile(
              title: TextFormField(
                decoration: InputDecoration(
                  labelText: selElement.otherText,
                ),
                controller: _controllers[index],
              ),
              value: _checkboxSelections[index]?["other"],
              contentPadding: EdgeInsets.only(bottom: 1.0),
              onChanged: (bool? value) {
                setState(() {
                  _checkboxSelections[index]?["other"] = value!;
                });
              },
            )
          );
        }
      }
    }

    return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: seList
        ),
    );
  }
}