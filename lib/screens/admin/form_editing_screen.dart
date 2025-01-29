import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import 'package:who_app/screens/map_widget.dart';
import '../../models/form_element.dart';
import '../../models/page.dart' as page_model;
import '../../models/selection.dart';
import '../../models/text.dart' as text_model;
import '../../models/location.dart' as loc_model;
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/form.dart' as form_model;


class FormEditingScreen extends StatefulWidget {

  final Map<String, dynamic> _form;

  final int _pageNumber;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  factory FormEditingScreen({
    Key? key,
    Map<String, dynamic>? form,
    int? pageNumber,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) {

    key = key ?? UniqueKey();

    pageNumber = pageNumber ?? 1;

    if(form != null){
      Map<String, dynamic> pages = form['pages'] as Map<String, dynamic>;
      if(pageNumber > pages.length){
        pages[pageNumber.toString()] = page_model.Page(title: "", description: "", elements: {}).toJson();
      }
    }else{
      form = form_model.Form(title: "", pages: {1: page_model.Page(title: "", description: "", elements: {})}).toJson();
    }

    return FormEditingScreen._internal(key: key, form: form, pageNumber: pageNumber, db: db, auth: auth);
  }

  FormEditingScreen._internal({
    required super.key,
    required Map<String, dynamic> form,
    required int pageNumber,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _form = form,
        _pageNumber = pageNumber,
        _db = db,
        _auth = auth;


  @override
  State<FormEditingScreen> createState() => _FormEditingScreenState();
}

class _FormEditingScreenState extends State<FormEditingScreen> {

  final _formKey = GlobalKey<FormState>();

  late page_model.Page _page;

  late int _selectedElement;

  @override
  void initState() {

    super.initState();
    widget._auth.authStateChanges().asBroadcastStream().listen((User? user) async {

      if (user == null || (await widget._db.collection('users').doc(user.uid).get()).data()!['role'] != 'admin') {

        bool exists = false;
        Navigator.popUntil(context, (route) {
          if (route.settings.name == '/login') {
            exists = true;
          }
          return true;
        });
        if (!exists) {
          Navigator.pushNamed(context, '/login');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {

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
                  builder: (context) => FormScreenAdmin(
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
        )
    );
  }

  Widget makeWidget(int index, FormElement element){

    List<Widget> elements = [
      Row(
        children: [
          Text(element.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  _page.elements.remove(index);
                });
              },
              icon: Icon(Icons.delete)
          )
        ],
      ),
      Text(element.subTitle,
        style: TextStyle(
          fontSize: 12,
        ),
      ),
    ];

    if(element.runtimeType == text_model.Text){

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
    }else if(element.runtimeType == loc_model.Location) {
      loc_model.Location locElement = element as loc_model.Location;

      elements.add(
          Stack(
              children: [
                MapWidget(address: locElement.address,
                    coordinates: locElement.coordinates,
                    required: locElement.required),
                Positioned.fill(
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ]
          )
      );
    }

    List<Widget> finalElements = [
      GestureDetector(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: elements
        ),
        onTap: () {
          setState(() {
            _selectedElement = index;
          });
        },
      )
    ];

    if(index != _page.elements.length && _selectedElement == index){
      finalElements.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    child: Text("Text field"),
                    onPressed: () => _activate(MenuEntry.about),
                  ),
                  MenuItemButton(
                    child: Text("Radio buttons"),
                    onPressed: () => _activate(MenuEntry.about),
                  ),
                  MenuItemButton(
                    child: Text("Checkboxes"),
                    onPressed: () => _activate(MenuEntry.about),
                  ),
                  MenuItemButton(
                    child: Text("Location field"),
                    onPressed: () => _activate(MenuEntry.about),
                  ),
                ],
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: Icon(Icons.add),
                  );
                },
              )
            ],
          )
      );
    }

    Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: finalElements
        )
    );
  }
}