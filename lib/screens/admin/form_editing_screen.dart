import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  final TextEditingController _pageTitleController = TextEditingController();

  final TextEditingController _pageDescriptionController = TextEditingController();

  String _newElementType = "";

  int _newElementIndex = -1;

  bool _newElementRequired = false;

  bool _newElementOther = false;

  bool _newOption = false;

  int _newElementNumSelections = 1;

  final List<String> _newElementOptions = [];

  final TextEditingController _optionController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

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

    _page = page_model.Page.fromJson(widget._form['pages'][widget._pageNumber.toString()]);
  }

  @override
  Widget build(BuildContext context) {

    _pageTitleController.text = _page.title;
    _pageDescriptionController.text = _page.description;

    List<Widget> seList = [];
    seList += [
      TextFormField(
        controller: _pageDescriptionController,
        decoration: InputDecoration(
          hintText: "Enter Page description",
        ),
      ),
      Divider(
        color: Colors.black,
        thickness: 1,
      ),
      SizedBox(height: 30)
    ];
    List<Widget> elements = _page.elements.map((k,v) => MapEntry(k, makeWidget(k, v))).values.toList();
    if(_newElementType != ""){
      elements.insert(_newElementIndex, makeNewElement(_newElementType));
    }

    seList += elements;

    List<Widget> actions = [
      IconButton(
        icon: widget._form['pages'][(widget._pageNumber+1).toString()] != null ? Icon(Icons.arrow_forward) : Icon(Icons.add),
        tooltip: 'Next page',
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormEditingScreen(
                form: widget._form,
                pageNumber: widget._pageNumber + 1,
                db: widget._db,
                auth: widget._auth,
              ),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.check),
        tooltip: 'Create Form',
        onPressed: () async {

          bool exists = false;
          Navigator.popUntil(context, (route) {
            if (route.settings.name == '/forms_admin') {
              exists = true;
            }
            return true;
          });
          if (!exists) {
            Navigator.pushNamed(context, '/forms_admin');
          }
        },
      )
    ];

    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: TextFormField(
              controller: _pageTitleController,
              decoration: InputDecoration(
                hintText: "Enter Page title",
              ),
            ),
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
                    onPressed: () => setState(() {
                      _newElementType = "text";
                      _newElementIndex = index;
                      _selectedElement = -1;
                    }),
                  ),
                  MenuItemButton(
                    child: Text("Radio buttons"),
                    onPressed: () => setState(() {
                      _newElementType = "radio";
                      _newElementIndex = index;
                      _selectedElement = -1;
                    }),
                  ),
                  MenuItemButton(
                    child: Text("Checkboxes"),
                    onPressed: () => setState(() {
                      _newElementType = "checkbox";
                      _newElementIndex = index;
                      _selectedElement = -1;
                    }),
                  ),
                  MenuItemButton(
                    child: Text("Location field"),
                    onPressed: () => setState(() {
                      _newElementType = "location";
                      _newElementIndex = index;
                      _selectedElement = -1;
                    }),
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

    return Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: finalElements
        )
    );
  }

  Widget makeNewElement(String type) {

    List<Widget> elements = [
      Row(
        children: [
          Text("Title  ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: "Your answer",
            ),
          ),
          Row(
            children: [
              Checkbox(
                  value: _newElementRequired,
                  onChanged: (value) {
                    setState(() {
                      _newElementRequired = value ?? false;
                    });
                  }
              ),
              Text("Required")
            ],
          )
        ],
      ),
      Row(
        children: [
          Text("Description  ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: "Your answer",
            ),
          )
        ],
      )
    ];

    if(type == "text"){

      elements.add(
          TextFormField(
            readOnly: true,
          )
      );
    }else if(type == "location"){

      elements.add(
          Stack(
              children: [
                MapWidget(address: "", coordinates: LatLng(45.4685, 9.1824), required: false),
                Positioned.fill(
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ]
          )
      );
    }else{

      final buttons = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.cancel),
            tooltip: 'Cancel',
            onPressed: () {
              setState(() {
                _newOption = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            tooltip: 'Confirm',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _newOption = false;
                _newElementOptions.add(_optionController.text);
                _optionController.text = "";
              }
            },
          )
        ],
      );

      List<Widget> selections = [];
      if(type == "radio"){

        for(String option in _newElementOptions){
          selections.add(
              RadioListTile<String>(
                  title: TextFormField(
                    readOnly: true,
                    initialValue: option,
                  ),
                  value: option,
                  groupValue: "",
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: null
              )
          );
        }

        if(_newOption){

          selections.add(
              RadioListTile<String>(
                  title: TextFormField(
                    controller: _optionController,
                  ),
                  value: "new",
                  groupValue: "",
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: null
              )
          );
          _newOption = false;
        }
      }else if(type == "checkbox"){

        for(String option in _newElementOptions){
          selections.add(
              CheckboxListTile(
                  title: TextFormField(
                    readOnly: true,
                    initialValue: option,
                  ),
                  value: false,
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: null
              )
          );
        }

        if(_newOption){

          selections.add(
            Row(
              children: [
                CheckboxListTile(
                    title: TextFormField(
                      controller: _optionController,
                    ),
                    value: false,
                    contentPadding: EdgeInsets.only(bottom: 1.0),
                    onChanged: null
                ),
                buttons
              ],
            )
          );
          _newOption = false;
        }
      }

      selections.add(
          IconButton(
            onPressed: () {
              setState(() {
                _newOption = true;
              });
            },
            icon: Icon(Icons.add),
          )
      );

      elements.add(
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selections
          )
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Form(
            key: _formKey,
            child: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: elements
                    )
                )
            )
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancel',
              onPressed: () {
                setState(() {
                  _newElementType = "";
                  _newElementIndex = -1;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Confirm',
              onPressed: () {

                if (_formKey.currentState!.validate()) {


                }
              },
            )
          ],
        )
      ],
    );
  }
}