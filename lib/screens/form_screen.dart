import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
import 'image_edit_screen.dart';
import 'package:universal_html/html.dart' as html;
import 'package:cookie_jar/cookie_jar.dart';

class FormScreen extends StatefulWidget {

  final String _formId;

  final Map<String, dynamic> _form;

  final Map<int, page_model.Page> _computedPages;

  final int _pageNumber;

  Map<int, Uint8List> _screenshots;

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
        _computedPages = (pageNumber == -1) ? ((form['pages'] as Map<String, dynamic>).map((k,v) => MapEntry(int.parse(k), computedPages[int.parse(k)] ?? page_model.Page.fromJson(v)))) : (computedPages..[pageNumber] = page_model.Page.fromJson(form['pages'][pageNumber.toString()])),
        _screenshots = screenshots ?? {},
        _db = db,
        _auth = auth;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {

  final _formKey = GlobalKey<FormState>();

  final Map<int,Map<int, String?>> _radioSelections = {};

  final Map<int,Map<int, Map<String, bool>?>> _checkboxSelections = {};

  final Map<int,Map<int, TextEditingController>> _controllers = {};

  final Map<int,Map<int, MapWidget>> _mapWidgets = {};

  late page_model.Page _page;

  final Map<int,ScreenshotController> _screenshotController = {};

  bool _specialCheckbox = false;

  late Map<String, dynamic> _userData;

  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploading = false;

  final Map<int, String> _selectionErrors = {};

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
              await storageRef.putData(file, SettableMetadata(
                contentType: 'image/jpeg'
              ));
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

    if(widget._pageNumber == -1){
      return makeAllPages();
    }else{
      return makePage();
    }
  }

  Widget makePage() {

    page_model.Page page = widget._computedPages[widget._pageNumber]!;

    if(_screenshotController[widget._pageNumber] == null){
      _screenshotController[widget._pageNumber] = ScreenshotController();
    }

    List<Widget> actions = [];
    if(defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android){
      actions.add(
          IconButton(
            icon: const Icon(Icons.format_align_justify),
            tooltip: 'Switch to single-page mode',
            onPressed: () {

                writeChanges({widget._pageNumber: page});
                // widget._form['pages'] = widget._computedPages.map((k,v) => MapEntry(k.toString(), v.toJson()));

                Navigator.popUntil(context, (route) {
                  if (route.settings.name == '/forms') {
                    return true;
                  }
                  return false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormScreen(
                      formId: widget._formId,
                      form: widget._form,
                      pageNumber: -1,
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
    if(widget._form['pages'][(widget._pageNumber+1).toString()] != null){
      actions.add(
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Next page',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {

                writeChanges({widget._pageNumber: page});
                widget._screenshots[widget._pageNumber] = (await _screenshotController[widget._pageNumber]!.capture())!;

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
            tooltip: 'Submit form',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _uploadAllImages();
                writeChanges({widget._pageNumber: page});
                widget._screenshots[widget._pageNumber] = (await _screenshotController[widget._pageNumber]!.capture())!;
                parsePdfAndMail();

                User? user = widget._auth.currentUser;
                String userId = "";
                if(user != null){

                  userId = user.uid;
                }else if(kIsWeb){

                  final cookies = html.document.cookie?.split('; ') ?? [];
                  for (final cookie in cookies) {
                    final parts = cookie.split('=');
                    if (parts[0] == 'guest_id') {
                      userId = parts[1];
                    }
                  }

                  final domain = html.window.location.hostname;
                  if(userId == ''){
                    userId = Uuid().v4();
                    final cookie = 'guest_id=$userId; expires=${DateTime.now().add(Duration(days: 365))}; path=/; domain=$domain';
                    html.document.cookie = cookie;
                  }
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

                Navigator.popUntil(context, (route) {
                  if (route.settings.name == '/forms') {
                    return true;
                  }
                  return false;
                });
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
          if(page.description.isNotEmpty){
            seList += [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(page.description,
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

            for(FormElement element in page.elements.values){

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
          seList += page.elements.map((k,v) => MapEntry(k, makeWidget(k, v, widget._pageNumber))).values.toList();

          return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(page.title),
                actions: actions
            ),
            resizeToAvoidBottomInset: true,
            body: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Screenshot(
                      controller: _screenshotController[widget._pageNumber]!,
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

  Widget makeAllPages() {

    for(int pageNum in widget._computedPages.keys){
      if(_screenshotController[pageNum] == null){
        _screenshotController[pageNum] = ScreenshotController();
      }
    }

    List<Widget> actions = [
      IconButton(
        tooltip: 'Switch to multi-page mode',
        onPressed: () {

            writeChanges(widget._computedPages);
            // widget._form['pages'] = widget._computedPages.map((k,v) => MapEntry(k.toString(), v.toJson()));

            Navigator.pushReplacement(context,
              MaterialPageRoute(
                builder: (context) => FormScreen(
                  formId: widget._formId,
                  form: widget._form,
                  pageNumber: 1,
                  computedPages: widget._computedPages,
                  db: widget._db,
                  auth: widget._auth,
                ),
              )
            );
        },
        icon: Icon(Icons.insert_page_break),
      ),
      IconButton(
        tooltip: 'Submit form',
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            await _uploadAllImages();
            writeChanges(widget._computedPages);
            widget._screenshots = Map.fromEntries(await Future.wait(
                _screenshotController.entries.map((x) async {
                  return MapEntry(x.key, (await x.value.capture())!);
                })
            ));
            parsePdfAndMail();

            User? user = widget._auth.currentUser;
            String userId = "";
            if(user != null){

              userId = user.uid;
            }else if(kIsWeb){

              final cookies = html.document.cookie?.split('; ') ?? [];
              for (final cookie in cookies) {
                final parts = cookie.split('=');
                if (parts[0] == 'guest_id') {
                  userId = parts[1];
                }
              }

              final domain = html.window.location.hostname;
              if(userId == ''){
                userId = Uuid().v4();
                final cookie = 'guest_id=$userId; expires=${DateTime.now().add(Duration(days: 365))}; path=/; domain=$domain';
                html.document.cookie = cookie;
              }
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

            Navigator.popUntil(context, (route) {
              if (route.settings.name == '/forms') {
                return true;
              }
              return false;
            });
          }
        },
        icon: Icon(Icons.check),
      )
    ];

    final user = widget._auth.currentUser;
    return FutureBuilder(
        future: user != null ? widget._db.collection('users').doc(user.uid).get() : Future.value("not signed in"),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          List<Widget> pages = [];

          if(snapshot.data != "not signed in"){
            _userData = (snapshot.data! as DocumentSnapshot<Map<String, dynamic>>).data()!;

            for(FormElement element in widget._computedPages.values.map((x) => x.elements.values).expand((x) => x)){

              if(element.runtimeType == text_model.Text && (element as text_model.Text).special != ""){

                pages += [
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

          for(final pageEntry in widget._computedPages.entries){

            List<Widget> seList = [];
            if(pageEntry.value.description.isNotEmpty){
              seList += [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(pageEntry.value.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(pageEntry.value.description,
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

            seList.add(SizedBox(height: 30));
            seList += pageEntry.value.elements.map((k,v) => MapEntry(k, makeWidget(k, v, pageEntry.key))).values.toList();
            if(pageEntry.key < (maxBy(widget._computedPages.keys, (x) => x) ?? -1)){
              seList += [
                Divider(
                  color: Colors.black,
                  thickness: 4,
                ),
                SizedBox(height: 30)
              ];
            }

            pages.add(
                Screenshot(
                  controller: _screenshotController[pageEntry.key]!,
                  child: Column(
                      children: seList
                  ),
                )
            );
          }

          return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget._form['title']),
                actions: actions
            ),
            resizeToAvoidBottomInset: true,
            body: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        children: pages
                    ),
                  ),
                )
            ),
          );
        }
    );
  }

  Widget makeWidget(int index, FormElement element, int pageNum) {

    List<Widget> elements = [
      Row(
        children: [
          Text(element.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Opacity(
              opacity: element.required ? 1.0 : 0.0,
            child: Text('*',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            )
          )
        ],
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
              style: ButtonStyle(
                side: WidgetStateProperty.all(
                    BorderSide(
                        color: Colors.white,
                        width: 2
                    )
                ),
              ),
              icon: Icon(Icons.add_photo_alternate,
                  color: Colors.white
              ),
              label: Text("Add Images",
                style: TextStyle(
                    color: Colors.white
                ),),
              onPressed: () async {
                final pickedFiles = await ImagePicker().pickMultiImage();
                if (pickedFiles.isEmpty) return;

                final futureImages = pickedFiles.map((file) => file.readAsBytes());
                final images = await Future.wait(futureImages);
                setState(() {
                  for (final pickedImage in images) {
                    imgElement.addImage(pickedImage);
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
                      child: Image.memory(
                        file,
                        fit: BoxFit.cover,
                      )
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      width: 142,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              child: Icon(Icons.edit, size: 24, color: Colors.white),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => imgElement.removeImage(index)),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 24, color: Colors.white),
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

      if(_controllers[pageNum] == null){
        _controllers[pageNum] = {};
      }
      if(_controllers[pageNum]![index] == null){
        _controllers[pageNum]![index] = TextEditingController();
        _controllers[pageNum]![index]!.text = txtElement.text;
      }

      final user = widget._auth.currentUser;
      if(user != null){
        switch (txtElement.special) {
          case 'institution':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? _userData['institution'] as String : "";
          case 'name':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? _userData['name'] as String : "";
          case 'position':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? _userData['position'] as String : "";
          case 'phone':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? _userData['phone'] as String : "";
          case 'email':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? user.email! : "";
          case 'country':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? _userData['country'] as String : "";
          case 'city':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? _userData['city'] as String : "";
          case 'unit':
            _controllers[pageNum]![index]!.text = _specialCheckbox ? _userData['unit'] as String : "";
        }
      }

      elements.add(TextFormField(
        decoration: InputDecoration(
          hintText: "Your answer",
        ),
        controller: _controllers[pageNum]![index],
        validator: (value) {
          if (txtElement.required && (value == null || value.isEmpty)) {
            return 'This field is required.';
          }
          return null;
        },
      ));

    }else if(element.runtimeType == Selection){

      Selection selElement = element as Selection;

      List<Widget> selections = [];

      if(selElement.numSelections == 1){

        if(_radioSelections[pageNum] == null){
          _radioSelections[pageNum] = {};
        }
        if(_radioSelections[pageNum]![index] == null){
          for(String k in selElement.selections.keys){
            if(selElement.selections[k]!) {
              _radioSelections[pageNum]![index] = k;
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
                  groupValue: _radioSelections[pageNum]![index],
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  onChanged: (String? value) {
                    setState(() {
                      _radioSelections[pageNum]![index] = value;
                    });
                  },
                )
            );
          }
        }

        if(selElement.other){

          if(_controllers[pageNum] == null){
            _controllers[pageNum] = {};
          }
          if(_controllers[pageNum]![index] == null){
            _controllers[pageNum]![index] = TextEditingController();
            _controllers[pageNum]![index]!.text = selElement.otherText!;
          }

          selections.add(
              RadioListTile<String>(
                title: TextFormField(
                  decoration: InputDecoration(
                    labelText: selElement.otherText,
                  ),
                  controller: _controllers[pageNum]![index],
                ),
                value: "other",
                groupValue: _radioSelections[pageNum]![index],
                contentPadding: EdgeInsets.only(bottom: 1.0),
                onChanged: (String? value) {
                  setState(() {
                    _radioSelections[pageNum]![index] = value;
                  });
                },
              )
          );
        }

        elements.add(
            FormField<bool>(
                builder: (state) {

                  if(state.hasError){
                    selections.add(
                        Text(state.errorText ?? '',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        )
                    );
                  }
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: selections
                  );
                },
                validator: (value) {
                  if (selElement.required && _radioSelections[pageNum]![index] == null) {
                    _selectionErrors[index] = 'Required field';
                    return _selectionErrors[index];
                  } else if(selElement.other && _radioSelections[pageNum]![index] == "other" && _controllers[pageNum]![index]!.text.isEmpty) {
                    _selectionErrors[index] = 'Please enter text for the Other field';
                    return _selectionErrors[index];
                  }else{
                    _selectionErrors[index] = '';
                    return null;
                  }
                }
            )
        );
      }else{

        if(_checkboxSelections[pageNum] == null){
          _checkboxSelections[pageNum] = {};
        }
        if(_checkboxSelections[pageNum]![index] == null){
          _checkboxSelections[pageNum]![index] = selElement.selections;
        }

        for(String key in selElement.selections.keys){
          if(key != "other"){
            selections.add(
                CheckboxListTile(
                  title: Text(key),
                  value: _checkboxSelections[pageNum]![index]![key],
                  contentPadding: EdgeInsets.only(bottom: 1.0),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? value) {
                    setState(() {
                      _checkboxSelections[pageNum]![index]![key] = value!;
                    });
                  },
                )
            );
          }
        }

        if(selElement.other) {

          if(_controllers[pageNum] == null){
            _controllers[pageNum] = {};
          }
          if(_controllers[pageNum]![index] == null){
            _controllers[pageNum]![index] = TextEditingController();
            _controllers[pageNum]![index]!.text = selElement.otherText!;
          }

          selections.add(
              CheckboxListTile(
                title: TextFormField(
                  decoration: InputDecoration(
                    labelText: selElement.otherText,
                  ),
                  controller: _controllers[pageNum]![index],
                ),
                value: _checkboxSelections[pageNum]![index]!["other"],
                contentPadding: EdgeInsets.only(bottom: 1.0),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  setState(() {
                    _checkboxSelections[pageNum]![index]!["other"] = value!;
                  });
                },
              )
          );
        }

        elements.add(
            FormField<bool>(
                builder: (state) {

                  return Column(
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: selections
                      ),
                      Visibility(
                        visible: (_selectionErrors[index] ?? '') != '',
                        child: Text(_selectionErrors[index] ?? '',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                validator: (value) {

                  final mustSelect = selElement.numSelections;
                  final numSelected = _checkboxSelections[pageNum]![index]!.values.where((x) => x).length;

                  if (numSelected != mustSelect) {
                    if(numSelected == 0 && !selElement.required){
                      _selectionErrors[index] = '';
                      return null;
                    }
                    _selectionErrors[index] = 'Required field. Please select $mustSelect options.';
                    return _selectionErrors[index];
                  } else if(selElement.other && _checkboxSelections[pageNum]![index]!["other"]! && _controllers[pageNum]![index]!.text.isEmpty){
                    _selectionErrors[index] = 'Please enter text for the Other field';
                    return _selectionErrors[index];
                  }else{
                    _selectionErrors[index] = '';
                    return null;
                  }
                }
            )
        );
      }
    }else if(element.runtimeType == loc_model.Location){

      loc_model.Location locElement = element as loc_model.Location;

      if(_mapWidgets[pageNum] == null){
        _mapWidgets[pageNum] = {};
      }
      if(_mapWidgets[pageNum]![index] == null){
        _mapWidgets[pageNum]![index] = MapWidget(address: locElement.address, coordinates: locElement.coordinates, required: locElement.required);
      }

      elements.add(_mapWidgets[pageNum]![index]!);
    }

    return Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: elements
        )
    );
  }

  void writeChanges(Map<int, page_model.Page> pageMap) {

    for(final pageEntry in pageMap.entries){

      final page = pageEntry.value;
      final pageNum = pageEntry.key;
      for(int index in page.elements.keys){

        FormElement element = page.elements[index]!;
        if(element.runtimeType == text_model.Text){

          (element as text_model.Text).text = _controllers[pageNum]![index]!.text;
        }else if(element.runtimeType == Selection){

          Selection selElement = element as Selection;

          if(selElement.numSelections == 1){
            selElement.selections = selElement.selections.map((k,v) => MapEntry(k, k == _radioSelections[pageNum]![index]));

            if(selElement.other && _radioSelections[pageNum]![index] == "other"){
              selElement.otherText = _controllers[pageNum]![index]!.text;
            }else{
              selElement.otherText = "";
            }
          }else{
            selElement.selections = _checkboxSelections[pageNum]![index]!;

            if(selElement.other && _checkboxSelections[pageNum]![index]!["other"] == true){
              selElement.otherText = _controllers[pageNum]![index]!.text;
            }else{
              selElement.otherText = "";
            }
          }
        }else if (element.runtimeType == image_model.ImagePickerElement) {

          image_model.ImagePickerElement imgElement = element as image_model.ImagePickerElement;
          imgElement.fileNames = imgElement.fileNames;
          imgElement.downloadUrls = imgElement.downloadUrls;
        }else{

          loc_model.Location locElement = element as loc_model.Location;

          locElement.address = _mapWidgets[pageNum]![index]!.address;
          locElement.coordinates = _mapWidgets[pageNum]![index]!.coordinates;
        }
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