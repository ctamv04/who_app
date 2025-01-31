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
import '../models/form_element.dart';
import '../models/page.dart' as page_model;
import '../models/selection.dart';
import '../models/text.dart' as text_model;
import '../models/location.dart' as loc_model;
import '../models/image_element.dart' as image_model;
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'image_edit_screen.dart';

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

  bool _specialCheckbox = false;

  late Map<String, dynamic> _userData;

  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploading = false;

  Future<void> _uploadAllImages() async {
  try {
    setState(() => _isUploading = true);
    
    for (final page in widget._computedPages.values) {
      for (final element in page.elements.values) {
        if (element is image_model.ImagePickerElement) {
          final imgElement = element;
          for (int i = 0; i < imgElement.imageFiles.length; i++) {
            if (imgElement.downloadUrls[i] == null) {
              final file = imgElement.imageFiles[i];
              final fileName = DateTime.now().millisecondsSinceEpoch.toString();
              final storageRef = FirebaseStorage.instance.ref("images/$fileName");
              await storageRef.putFile(file);
              final url = await storageRef.getDownloadURL();
              imgElement.downloadUrls[i] = url;
            }
          }
        }
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Image upload failed: $e")),
    );
    rethrow;
  } finally {
    setState(() => _isUploading = false);
  }
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
          IconButton(
            onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _uploadAllImages();
                  writeChanges();
                  widget._screenshots[widget._pageNumber] = (await _screenshotController.capture())!;
                  parsePdfAndMail();

                  User? user = widget._auth.currentUser;
                  String userId = "";
                  if(user != null){
                    userId = user.uid;
                  }else{
                    final path = (await getApplicationDocumentsDirectory()).path;
                    final file = File('$path/guest_id.txt');
                    if(await file.exists()){
                      userId = await file.readAsString();
                    }else{
                      userId = Uuid().v4();
                      await file.writeAsString(userId);
                    }
                  }

                  widget._form['pages'] = widget._computedPages.map((k,v) => MapEntry(k.toString(), v.toJson()));
                  widget._form['form_id'] = widget._formId;
                  widget._form['uid'] = userId;
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
            icon: Icon(Icons.check),
          )
      );
    }

    final user = widget._auth.currentUser;
    return FutureBuilder(
        future: user != null ? widget._db.collection('users').doc(user.uid).get() : Future.value("not signed in"),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

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

          if(snapshot.data != "not signed in"){
            _userData = (snapshot.data! as DocumentSnapshot<Map<String, dynamic>>).data()!;

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

  if (element.runtimeType == image_model.ImagePickerElement) {

    final imgElement = element as image_model.ImagePickerElement;

    elements.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.add_photo_alternate),
              label: Text("Add Images"),
              onPressed: () async {
                final pickedFiles = await ImagePicker().pickMultiImage();
                if (pickedFiles.isEmpty) return;

                setState(() {
                  for (final pickedFile in pickedFiles) {
                    imgElement.addImage(File(pickedFile.path));
                  }
                });
              },
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: imgElement.imageFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;

                return Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final editedFile = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DrawingPage(
                                    imageFile: file,
                                  ),
                                ),
                              );
                              if (editedFile != null) {
                                setState(() {
                                  imgElement.imageFiles[index] = editedFile;
                                  imgElement.downloadUrls[index] = null;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => imgElement.removeImage(index)),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        )
    );
  }else if(element.runtimeType == text_model.Text){

      text_model.Text txtElement = element as text_model.Text;

      if(_controllers[index] == null){
        _controllers[index] = TextEditingController();
        _controllers[index]!.text = txtElement.text;
      }

      final user = widget._auth.currentUser;
      if(user != null){
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
            _controllers[index]!.text = _specialCheckbox ? user.email! : "";
          case 'country':
            _controllers[index]!.text = _specialCheckbox ? _userData['country'] as String : "";
          case 'city':
            _controllers[index]!.text = _specialCheckbox ? _userData['city'] as String : "";
          case 'unit':
            _controllers[index]!.text = _specialCheckbox ? _userData['unit'] as String : "";
        }
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
      }
      else if (element.runtimeType == image_model.ImagePickerElement) {
    
      image_model.ImagePickerElement imgElement = element as image_model.ImagePickerElement;
      imgElement.fileNames = imgElement.fileNames;
      imgElement.downloadUrls = imgElement.downloadUrls;
    }
    else{

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
    final user = widget._auth.currentUser;
    String email = "";
    if(user != null){
      email = user.email!;
    }

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