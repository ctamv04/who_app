import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:who_app/screens/map_widget.dart';
import '../../models/form_element.dart';
import '../../models/page.dart' as page_model;
import '../../models/selection.dart';
import '../../models/text.dart' as text_model;
import '../../models/location.dart' as loc_model;
import '../../models/form.dart' as form_model;


class FormEditingScreen extends StatefulWidget {

  final String? _formId;

  final Map<String, dynamic> _form;

  final int _pageNumber;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  factory FormEditingScreen({
    Key? key,
    String? formId,
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

    return FormEditingScreen._internal(key: key, formId: formId, form: form, pageNumber: pageNumber, db: db, auth: auth);
  }

  FormEditingScreen._internal({
    required super.key,
    String? formId,
    required Map<String, dynamic> form,
    required int pageNumber,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _form = form,
        _formId = formId,
        _pageNumber = pageNumber,
        _db = db,
        _auth = auth;


  @override
  State<FormEditingScreen> createState() => _FormEditingScreenState();
}

class _FormEditingScreenState extends State<FormEditingScreen> {

  late StreamSubscription<User?> _subscription;

  final _formKey = GlobalKey<FormState>();

  GlobalKey<FormState> _optionFormKey = GlobalKey<FormState>();

  late page_model.Page _page;

  int _selectedElement = -1;

  final TextEditingController _pageTitleController = TextEditingController();

  final TextEditingController _pageDescriptionController = TextEditingController();

  String _newElementType = "";

  int _newElementIndex = -1;

  bool _newElementRequired = false;

  bool _newElementOther = false;

  bool _newOption = false;

  bool _noOptionsWarning = false;

  int _newElementNumSelections = 1;

  List<String> _newElementOptions = [];

  final TextEditingController _optionController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  late OverlayEntry _overlay;

  @override
  void initState() {

    super.initState();
    _subscription = widget._auth.authStateChanges().asBroadcastStream().listen((User? user) async {

      if (user == null || (await widget._db.collection('users').doc(user.uid).get()).data()!['role'] != 'admin') {

        Navigator.of(context).popUntil((route) => false);
        Navigator.pushNamed(context, '/login');
      }
    });

    final GlobalKey<FormState> titleFormKey = GlobalKey<FormState>();
    final formTitleController = TextEditingController();
    formTitleController.text = widget._form['title'];
    _overlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Form(
          key: titleFormKey,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Form title:  ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white
                      ),
                    ),
                    Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if ((value ?? "") == "") {
                              return 'Please enter text.';
                            }
                            return null;
                          },
                          controller: formTitleController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        )
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cancel,
                          color: Colors.white),
                      tooltip: 'Cancel',
                      onPressed: () {
                        _overlay.remove();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                        color: Colors.white,),
                      tooltip: 'Confirm',
                      onPressed: () {
                        if (titleFormKey.currentState!.validate()) {
                          _page.title = _pageTitleController.text;
                          _page.description = _pageDescriptionController.text;
                          widget._form['pages'][widget._pageNumber.toString()] = _page.toJson();
                          widget._form['title'] = formTitleController.text;
                          if(widget._formId == null){
                            widget._db.collection("forms").add(widget._form);
                          }else{
                            widget._db.collection('forms').doc(widget._formId).set(widget._form);
                          }

                          _overlay.remove();
                          bool exists = false;
                          Navigator.popUntil(context, (route) {
                            if (route.settings.name == '/forms_admin') {
                              exists = true;
                              return true;
                            }
                            return false;
                          });
                          if (!exists) {
                            Navigator.pushNamed(context, '/forms_admin');
                          }
                        }
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        )
      ),
    );

    _page = page_model.Page.fromJson(widget._form['pages'][widget._pageNumber.toString()]);
    _pageTitleController.text = _page.title;
    _pageDescriptionController.text = _page.description;
  }

  @override
  void dispose() {

    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> seList = [];
    seList += [
      TextField(
        controller: _pageDescriptionController,
        decoration: InputDecoration(
          hintText: "Enter Page description",
        ),
      ),
      // Divider(
      //   color: Colors.black,
      //   thickness: 1,
      // ),
      SizedBox(height: 30)
    ];

    List<Widget> elements = _page.elements.map((k,v) => MapEntry(k, makeWidget(k, v))).values.toList();
    if(_newElementType == ""){
      elements.add(
          Center(
            child: MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  child: Text("Text field"),
                  onPressed: () => setState(() {
                    _newElementType = "text";
                    _newElementIndex = _page.elements.length;
                    _selectedElement = -1;
                  }),
                ),
                MenuItemButton(
                  child: Text("Radio buttons"),
                  onPressed: () => setState(() {
                    _newElementType = "radio";
                    _newElementIndex = _page.elements.length;
                    _selectedElement = -1;
                  }),
                ),
                MenuItemButton(
                  child: Text("Checkboxes"),
                  onPressed: () => setState(() {
                    _newElementType = "checkbox";
                    _newElementIndex = _page.elements.length;
                    _selectedElement = -1;
                  }),
                ),
                MenuItemButton(
                  child: Text("Location field"),
                  onPressed: () => setState(() {
                    _newElementType = "location";
                    _newElementIndex = _page.elements.length;
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
          )
      );
    }else{
      elements.insert(_newElementIndex, makeNewElement(_newElementType));
    }

    seList += elements;

    List<Widget> actions = [
      IconButton(
        icon: widget._form['pages'][(widget._pageNumber+1).toString()] != null ? Icon(Icons.arrow_forward) : Icon(Icons.add),
        tooltip: 'Next page',
        onPressed: () {

            _page.title = _pageTitleController.text;
            _page.description = _pageDescriptionController.text;
            widget._form['pages'][widget._pageNumber.toString()] = _page.toJson();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FormEditingScreen(
                  formId: widget._formId,
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
        tooltip: 'Finalize Form',
        onPressed: () {
          Overlay.of(context).insert(_overlay);
        },
      )
    ];

    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: TextField(
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
          if(_newElementType == "")
            IconButton(
                onPressed: () {
                  setState(() {
                    _page.elements.remove(index);
                    _page.elements = _page.elements.map((k,v) => k >= index ? MapEntry(k-1, v) : MapEntry(k, v));
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

    if(_newElementType == "" && (index != _page.elements.length && _selectedElement == index)){
      finalElements.add(
          Center(
            child: MenuAnchor(
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
          Expanded(
            child: TextFormField(
              validator: (value) {
                if ((value ?? "") == "") {
                  return 'Please enter text.';
                }
                return null;
              },
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Your answer",
              ),
            )
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
          Expanded(
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "Your answer",
                ),
              )
          )
        ],
      )
    ];

    Widget nonCheckboxOption = Center(
        child: Row(
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
    );

    if(type == "text"){

      elements.add(nonCheckboxOption);
      elements.add(
          TextFormField(
            readOnly: true,
          )
      );
    }else if(type == "location"){

      elements.add(nonCheckboxOption);
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
              if (_optionFormKey.currentState!.validate()) {
                setState(() {
                  _newOption = false;
                  _newElementOptions.add(_optionController.text);
                  _optionController.text = "";
                });
              }
            },
          )
        ],
      );

      List<Widget> selections = [];
      if(type == "radio"){

        elements.add(nonCheckboxOption);

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
              Form(
                  key: _optionFormKey,
                  child: SingleChildScrollView(
                      child: Row(
                          children: [
                            Expanded(
                                child: RadioListTile<String>(
                                    title: TextFormField(
                                      validator: (value) {
                                        if ((value ?? "") == "") {
                                          return 'Please enter text.';
                                        }
                                        return null;
                                      },
                                      controller: _optionController,
                                    ),
                                    value: "new",
                                    groupValue: "",
                                    contentPadding: EdgeInsets.only(bottom: 1.0),
                                    onChanged: null
                                )
                            ),
                            buttons
                          ]
                      )
                  )
              )
          );
          _newOption = false;
        }
      }else if(type == "checkbox"){

        elements.add(
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      ),
                      Row(
                        children: [
                          Checkbox(
                              value: _newElementOther,
                              onChanged: (value) {
                                setState(() {
                                  _newElementOther = value ?? false;
                                });
                              }
                          ),
                          Text("Include 'Other' option")
                        ],
                      ),
                    ],
                  ),
                  DropdownMenu(
                    width: 180.0,
                    label: const Text('Selections'),
                    dropdownMenuEntries: List.generate(_newElementOptions.length, (idx) => DropdownMenuEntry(value: 1+idx, label: (1+idx).toString())),
                    initialSelection: _newElementOptions.isNotEmpty ? 1 : null,
                    onSelected: (int? value) {
                      setState(() {
                        _newElementNumSelections = value ?? 1;
                      });
                    },
                  )
                ],
              ),
            )
        );

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
              Form(
                  key: _optionFormKey,
                  child: SingleChildScrollView(
                      child: Row(
                        children: [
                          Expanded(
                              child: CheckboxListTile(
                                  title: TextFormField(
                                    validator: (value) {
                                      if ((value ?? "") == "") {
                                        return 'Please enter text.';
                                      }
                                      return null;
                                    },
                                    controller: _optionController,
                                  ),
                                  value: false,
                                  contentPadding: EdgeInsets.only(bottom: 1.0),
                                  onChanged: null
                              )
                          ),
                          buttons
                        ],
                      )
                  )
              )
          );
          _newOption = false;
        }
      }

      selections.add(
        Center(
          child: IconButton(
            onPressed: () {
              setState(() {
                _newOption = true;
                _optionFormKey = GlobalKey<FormState>();
              });
            },
            icon: Icon(Icons.add),
          )
        )
      );

      elements.add(
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selections
          )
      );
    }

    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
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
            Visibility(
                visible: _noOptionsWarning,
                child: Text('Please create at least one option.',
                  style: TextStyle(
                      color: Colors.red
                  ),
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
                      cleanup();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle),
                  tooltip: 'Confirm',
                  onPressed: () {

                    if (_formKey.currentState!.validate()) {
                      if((_newElementType == 'radio' || _newElementType == 'checkbox') && _newElementOptions.isEmpty){
                        setState(() {
                          _noOptionsWarning = true;
                        });
                      }else{
                        setState(() {
                          _page.elements = _page.elements.map((k,v) => k >= _newElementIndex ? MapEntry(k+1, v) : MapEntry(k, v));
                          if(_newElementType == "text"){
                            _page.elements[_newElementIndex] = text_model.Text(title: _titleController.text, subTitle: _descriptionController.text, required: _newElementRequired);
                          }else if(_newElementType == "location"){
                            _page.elements[_newElementIndex] = loc_model.Location(title: _titleController.text, subTitle: _descriptionController.text, required: _newElementRequired);
                          }else{
                            _page.elements[_newElementIndex] = Selection(title: _titleController.text, subTitle: _descriptionController.text, required: _newElementRequired, selections: {for (var option in _newElementOptions) option: false}, numSelections: _newElementNumSelections, other: _newElementOther);
                          }
                          _page.elements = SplayTreeMap<int, FormElement>.from(_page.elements);

                          cleanup();
                        });
                      }
                    }
                  },
                )
              ],
            )
          ],
        )
    );
  }

  void cleanup(){
    _newElementType = "";
    _newElementIndex = -1;
    _titleController.text = "";
    _descriptionController.text = "";
    _newElementRequired = false;
    _newOption = false;
    _newElementOptions = [];
    _newElementNumSelections = 1;
    _newElementOther = false;
    _noOptionsWarning = false;
  }
}