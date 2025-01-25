import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:screenshot/screenshot.dart';
import 'package:who_app/screens/map_widget.dart';
import '../models/form_element.dart';
import '../models/page.dart' as page_model;
import '../models/selection.dart';
import '../models/text.dart' as text_model;
import '../models/location.dart' as loc_model;
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class FormScreen extends StatefulWidget {

  final String _formId;

  final Map<String, dynamic> _form;

  final Map<int, page_model.Page> _computedPages;

  final int _pageNumber;

  final Map<int, Uint8List> _screenshots;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  FormScreen({
    super.key,
    required String formId,
    required Map<String, dynamic> form,
    required int pageNumber,
    required Map<int, page_model.Page> computedPages,
    Map<int, Uint8List>? screenshots,
    required FirebaseFirestore db,
    required FirebaseAuth auth,
  }) :  _formId = formId,
        _form = form,
        _pageNumber = pageNumber,
        _computedPages = computedPages..[pageNumber] = page_model.Page.fromJson(form['pages'][pageNumber.toString()]),
        _screenshots = screenshots ?? {},
        _db = db,
        _auth = auth;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {

  final _formKey = GlobalKey<FormState>();

  final Map<int, String?> _radioSelections = {};

  final Map<int, Map<String, bool>?> _checkboxSelections = {};

  final Map<int, TextEditingController> _controllers = {};

  final Map<int, MapWidget> _mapWidgets = {};

  late page_model.Page _page;

  final ScreenshotController _screenshotController = ScreenshotController();

  final Map<int, text_model.Text> _specialElements = {};

  final Map<int, Widget> _specialWidgets = {};

  bool _specialCheckbox = false;

  late Map<String, dynamic> _userData;

  @override
  void initState() {

    super.initState();
    widget._auth.authStateChanges().asBroadcastStream().listen((User? user) async {

      if (user == null) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not authorized to access this page. Please sign in.'),
            duration: Duration(seconds: 4),
          ),
        );

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
  void dispose() {

    for(TextEditingController controller in _controllers.values){
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    _page = widget._computedPages[widget._pageNumber]!;

    List<Widget> actions = [];
    if(widget._form['pages'][(widget._pageNumber+1).toString()] != null){
      actions.add(
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Next page',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {

                writeChanges();
                widget._screenshots[widget._pageNumber] = (await _screenshotController.capture())!;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormScreen(
                        formId: widget._formId,
                        form: widget._form,
                        pageNumber: widget._pageNumber + 1,
                        computedPages: widget._computedPages,
                        screenshots: widget._screenshots,
                        db: widget._db,
                        auth: widget._auth,
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
            onPressed: () async {
                if (_formKey.currentState!.validate()) {

                  writeChanges();
                  widget._screenshots[widget._pageNumber] = (await _screenshotController.capture())!;
                  parsePdfAndMail();

                  widget._form['pages'] = widget._computedPages.map((k,v) => MapEntry(k.toString(), v.toJson()));
                  widget._form['form_id'] = widget._formId;
                  widget._form['uid'] = widget._auth.currentUser!.uid;
                  widget._form['date'] = DateTime.now().toString();
                  widget._db.collection("filled_forms").add(widget._form);

                  bool exists = false;
                  Navigator.popUntil(context, (route) {
                    if (route.settings.name == '/forms') {
                      exists = true;
                    }
                    return true;
                  });
                  if (!exists) {
                    Navigator.pushNamed(context, '/forms');
                  }
                }
            },
            child: const Text('Submit'),
          )
      );
    }

    return FutureBuilder(
        future: widget._db.collection('users').doc(widget._auth.currentUser!.uid).get(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          _userData = snapshot.data!.data()!;

          List<Widget> seList = [];
          if(_page.description.isNotEmpty){
            seList += [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_page.description,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Divider(
                    color: Colors.black,
                    thickness: 1,
                  ),
                ],
              )
            ];
          }
          for(FormElement element in _page.elements.values){

            if(element.runtimeType == text_model.Text && (element as text_model.Text).special != ""){

              seList += [
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Use information from profile"),
                    Checkbox(value: _specialCheckbox, onChanged: (value) {
                      setState(() {
                        _specialCheckbox = value ?? false;
                      });
                    })
                  ],
                )
              ];
              break;
            }
          }
          seList.add(SizedBox(height: 30));
          seList += _page.elements.map((k,v) => MapEntry(k, makeWidget(k, v))).values.toList();

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
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Column(
                          children: seList
                      ),
                    ),
                  ),
                )
            ),
          );
        }
    );
  }

  Widget makeWidget(int index, FormElement element) {

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

      text_model.Text txtElement = element as text_model.Text;

      if(_controllers[index] == null){
        _controllers[index] = TextEditingController();
        _controllers[index]!.text = txtElement.text;
      }

      switch (txtElement.special) {
        case 'institution':
          _controllers[index]!.text = _specialCheckbox ? _userData['institution'] as String : "";
        case 'name':
          _controllers[index]!.text = _specialCheckbox ? _userData['name'] as String : "";
        case 'position':
          _controllers[index]!.text = _specialCheckbox ? _userData['position'] as String : "";
        case 'phone':
          _controllers[index]!.text = _specialCheckbox ? _userData['phone'] as String : "";
        case 'email':
          _controllers[index]!.text = _specialCheckbox ? widget._auth.currentUser!.email! : "";
        case 'country':
          _controllers[index]!.text = _specialCheckbox ? _userData['country'] as String : "";
        case 'city':
          _controllers[index]!.text = _specialCheckbox ? _userData['city'] as String : "";
        case 'unit':
          _controllers[index]!.text = _specialCheckbox ? _userData['unit'] as String : "";
      }

      elements.add(TextFormField(
        decoration: InputDecoration(
          hintText: "Your answer",
        ),
        controller: _controllers[index],
        validator: (value) {
          if (_page.elements[index]!.required && (value == null || value.isEmpty)) {
            return 'This field is required.';
          }
          return null;
        },
        readOnly: _specialCheckbox,
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
            _controllers[index]!.text = selElement.otherText!;
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
            _controllers[index]!.text = selElement.otherText!;
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

  void parsePdfAndMail() async {

    final pdf = pw.Document();

    for(Uint8List image in widget._screenshots.values){
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Expanded(
                child: pw.Image(pw.MemoryImage(image), fit: pw.BoxFit.contain)
            );
          },
      ));
    }

    final data = await pdf.save();
    final base64data = base64Encode(data).toString();

    String formName = widget._form['title'] as String;
    String email = widget._auth.currentUser!.email!;
    widget._db.collection("email").add({
      'to': 'ctamvakas@gmail.com',
      'template': {
        'name': 'default',
        'data': {
          'form_name': formName,
          'user_email': email,
          'filename': '$formName$email${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
          'content': base64data,
        },
      },
    });
  }
}