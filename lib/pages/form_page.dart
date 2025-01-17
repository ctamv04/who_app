import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:who_app/pages/map_widget.dart';
import '../models/form_element.dart';
import '../models/page.dart' as page_model;
import '../models/selection.dart';
import '../models/text.dart' as text_model;
import '../models/location.dart' as loc_model;

class FormPage extends StatefulWidget {

  final Map<String, dynamic> _form;

  final Map<int, page_model.Page> _computedPages;

  final int _pageNumber;

  final FirebaseFirestore _db;

  FormPage({
    super.key,
    required Map<String, dynamic> form,
    required int pageNumber,
    required Map<int, page_model.Page> computedPages,
    required FirebaseFirestore db
  }) : _form = form,
        _pageNumber = pageNumber,
        _computedPages = computedPages..[pageNumber] = page_model.Page.fromJson(form['pages'][pageNumber.toString()]),
        _db = db;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {

  final _formKey = GlobalKey<FormState>();

  final Map<int, String?> _radioSelections = {};

  final Map<int, Map<String, bool>?> _checkboxSelections = {};

  final Map<int, TextEditingController> _controllers = {};

  final Map<int, MapWidget> _mapWidgets = {};

  late page_model.Page _page;

  @override
  void dispose() {

    for(TextEditingController controller in _controllers.values){
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    _page = widget._computedPages[widget._pageNumber]!;

    List<Widget> seList = [];
    if(_page.description.isNotEmpty){
      seList += [
        Text(_page.description,
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        Divider(
          color: Colors.black,
          thickness: 1,
        ),
        SizedBox(height: 30)
      ];
    }
    seList += _page.elements!.map((k,v) => MapEntry(k, makeWidget(k, v))).values.toList();

    List<Widget> actions = [];
    if(widget._form['pages'][(widget._pageNumber+1).toString()] != null){
      actions.add(
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Next page',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                writeChanges();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormPage(
                        form: widget._form,
                        pageNumber: widget._pageNumber + 1,
                        computedPages: widget._computedPages,
                        db: widget._db
                    ),
                  ),
                );
              }
            },
          )
      );
    }else{
      actions.add(
          TextButton(
            onPressed: () {
                if (_formKey.currentState!.validate()) {
                  writeChanges();
                  widget._db.collection("filled_forms").add(widget._form..['pages'] = widget._computedPages.map((k,v) => MapEntry(k.toString(), v.toJson())));
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                }
            },
            child: const Text('Submit'),
          )
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_page.title),
        actions: actions
      ),
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                children: seList
            ),
          ),
        )
      ),
    );
  }

  Widget makeWidget(int index, FormElement element){

    List<Widget> elements = [
      Text(element.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      Text(element.subTitle,
        style: TextStyle(
          fontSize: 12,
        ),
      ),
    ];

    if(element.runtimeType == text_model.Text){

      if(_controllers[index] == null){
        _controllers[index] = TextEditingController();
      }

      elements.add(TextFormField(
        decoration: InputDecoration(
          hintText: "Your answer",
        ),
        controller: _controllers[index],
        validator: (value) {
          if (_page.elements![index]!.required && (value == null || value.isEmpty)) {
            return 'This field is required.';
          }
          return null;
        },
      ));

    }else if(element.runtimeType == Selection){

      Selection selElement = element as Selection;

      List<Widget> selections = [];

      if(selElement.numSelections == 1){

        if(_radioSelections[index] == null){
          for(String k in selElement.selections.keys){
            if(selElement.selections[k]!) {
              _radioSelections[index] = k;
              break;
            }
          }
        }

        for(String key in selElement.selections.keys){
          if(key != "other"){
            selections.add(
                RadioListTile<String>(
                  title: Text(key),
                  value: key,
                  groupValue: _radioSelections[index],
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: (String? value) {
                    setState(() {
                      _radioSelections[index] = value;
                    });
                  },
                )
            );
          }
        }

        if(selElement.other){

          if(_controllers[index] == null){
            _controllers[index] = TextEditingController();
          }

          selections.add(
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
                    _radioSelections[index] = value;
                  });
                },
              )
          );
        }

        elements.add(
            FormField<bool>(
                builder: (state) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: selections
                  );
                },
                validator: (value) {
                  if (selElement.required && _radioSelections[index] == null) {
                    return 'Required field';
                  } else if(selElement.other && _radioSelections[index] == "other" && _controllers[index]!.text.isEmpty) {
                    return 'Please enter text for the Other field';
                  }else{
                    return null;
                  }
                }
            )
        );
      }else{

        if(_checkboxSelections[index] == null){
          _checkboxSelections[index] = selElement.selections;
        }

        for(String key in selElement.selections.keys){
          if(key != "other"){
            selections.add(
                CheckboxListTile(
                  title: Text(key),
                  value: _checkboxSelections[index]?[key],
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: (bool? value) {
                    setState(() {
                      _checkboxSelections[index]?[key] = value!;
                    });
                  },
                )
            );
          }
        }

        if(selElement.other) {

          if(_controllers[index] == null){
            _controllers[index] = TextEditingController();
          }

          selections.add(
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

        elements.add(
            FormField<bool>(
                builder: (state) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: selections
                  );
                },
                validator: (value) {

                  final mustSelect = selElement.numSelections;
                  final numSelected = _checkboxSelections[index]!.values.where((x) => x).length;

                  if (numSelected != mustSelect) {
                    if(numSelected == 0 && !selElement.required){
                      return null;
                    }
                    return 'Required field. Please select $mustSelect options.';
                  } else if(selElement.other && _checkboxSelections[index]!["other"]! && _controllers[index]!.text.isEmpty){
                    return 'Please enter text for the Other field';
                  }else{
                    return null;
                  }
                }
            )
        );
      }
    }else if(element.runtimeType == loc_model.Location){

      loc_model.Location locElement = element as loc_model.Location;

      if(!_mapWidgets.containsKey(index)){
        _mapWidgets[index] = MapWidget(address: locElement.address, coordinates: locElement.coordinates, required: locElement.required);
      }
      elements.add(_mapWidgets[index]!);
    }

    return Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: elements
        )
    );
  }

  void writeChanges() {

    for(int index in _page.elements!.keys){

      FormElement element = _page.elements![index]!;
      if(element.runtimeType == text_model.Text){

        (element as text_model.Text).text = _controllers[index]!.text;
      }else if(element.runtimeType == Selection){

        Selection selElement = element as Selection;

        if(selElement.numSelections == 1){
          selElement.selections = selElement.selections.map((k,v) => MapEntry(k, k == _radioSelections[index]));

          if(selElement.other && _radioSelections[index] == "other"){
            selElement.otherText = _controllers[index]!.text;
          }else{
            selElement.otherText = "";
          }
        }else{
          selElement.selections = _checkboxSelections[index]!;

          if(selElement.other && _checkboxSelections[index]!["other"] == true){
            selElement.otherText = _controllers[index]!.text;
          }else{
            selElement.otherText = "";
          }
        }
      }else{

        loc_model.Location locElement = element as loc_model.Location;

        locElement.address = _mapWidgets[index]!.address;
        locElement.coordinates = _mapWidgets[index]!.coordinates;
      }
    }
  }
}