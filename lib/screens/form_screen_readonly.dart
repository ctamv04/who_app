import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:who_app/screens/map_widget.dart';
import '../../models/form_element.dart';
import '../../models/page.dart' as page_model;
import '../../models/selection.dart';
import '../../models/text.dart' as text_model;
import '../../models/location.dart' as loc_model;
import '../models/image_element.dart' as image_model;

class FormScreenReadOnly extends StatefulWidget {

  final Map<String, dynamic> _form;

  final Map<int, page_model.Page> _computedPages;

  final int _pageNumber;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  FormScreenReadOnly({
    super.key,
    required Map<String, dynamic> form,
    int? pageNumber,
    Map<int, page_model.Page>? computedPages,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _form = form,
        _pageNumber = pageNumber ?? 1,
        _computedPages = (computedPages != null && pageNumber != null) ? (computedPages..[pageNumber] = page_model.Page.fromJson(form['pages'][pageNumber.toString()])) : {},
        _db = db,
        _auth = auth;

  @override
  State<FormScreenReadOnly> createState() => _FormScreenReadOnlyState();
}

class _FormScreenReadOnlyState extends State<FormScreenReadOnly> {

  late page_model.Page _page;

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
    seList += _page.elements.map((k,v) => MapEntry(k, makeWidget(k, v))).values.toList();

    List<Widget> actions = [];
    if(widget._form['pages'][(widget._pageNumber+1).toString()] != null){
      actions.add(
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Next page',
            onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormScreenReadOnly(
                        form: widget._form,
                        pageNumber: widget._pageNumber + 1,
                        computedPages: widget._computedPages,
                        db: widget._db,
                        auth: widget._auth,
                    ),
                  ),
                );
            },
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
      body: SingleChildScrollView(
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

    if (element.runtimeType == image_model.ImagePickerElement) {
      final imgElement = element as image_model.ImagePickerElement;
      
      elements.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: imgElement.downloadUrls.map((url) {
            return Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: url != null 
                  ? Image.network(url, fit: BoxFit.cover)
                  : Icon(Icons.error_outline, color: Colors.red),
            );
          }).toList(),
        ),
      );
    }else if(element.runtimeType == text_model.Text){

      text_model.Text txtElement = element as text_model.Text;

      elements.add(TextFormField(
        readOnly: true,
        initialValue: txtElement.text,
      ));

    }else if(element.runtimeType == Selection){

      Selection selElement = element as Selection;

      List<Widget> selections = [];

      if(selElement.numSelections == 1){

        String radioSelection = "";
        for(String k in selElement.selections.keys){
          if(selElement.selections[k]!) {
            radioSelection = k;
            break;
          }
        }

        for(String key in selElement.selections.keys){
          if(key != "other"){
            selections.add(
                RadioListTile<String>(
                  title: Text(key),
                  value: key,
                  groupValue: radioSelection,
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: null
                )
            );
          }
        }

        if(selElement.other){

          selections.add(
              RadioListTile<String>(
                title: TextFormField(
                  readOnly: true,
                  initialValue: selElement.otherText,
                ),
                value: "other",
                groupValue: radioSelection,
                contentPadding: EdgeInsets.only(bottom: 1.0),
                onChanged: null
              )
          );
        }

        elements.add(
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selections
            )
        );
      }else{

        for(String key in selElement.selections.keys){
          if(key != "other"){
            selections.add(
                CheckboxListTile(
                  title: Text(key),
                  value: selElement.selections[key],
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: null
                )
            );
          }
        }

        if(selElement.other) {

          selections.add(
              CheckboxListTile(
                title: TextFormField(
                  readOnly: true,
                  initialValue: selElement.otherText,
                ),
                value: selElement.selections["other"],
                contentPadding: EdgeInsets.only(bottom: 1.0),
                onChanged: null
              )
          );
        }

        elements.add(
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selections
            )
        );
      }
    }else if(element.runtimeType == loc_model.Location){

      loc_model.Location locElement = element as loc_model.Location;

      elements.add(
          Stack(
              children: [
                MapWidget(address: locElement.address, coordinates: locElement.coordinates, required: locElement.required),
                Positioned.fill(
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ]
          )
      );
    }

    return Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: elements
        )
    );
  }
}