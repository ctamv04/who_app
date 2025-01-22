import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:who_app/screens/map_widget.dart';
import '../../models/form_element.dart';
import '../../models/page.dart' as page_model;
import '../../models/selection.dart';
import '../../models/text.dart' as text_model;
import '../../models/location.dart' as loc_model;

class FormScreenAdmin extends StatefulWidget {

  final Map<String, dynamic> _form;

  final Map<int, page_model.Page> _computedPages;

  final int _pageNumber;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  FormScreenAdmin({
    super.key,
    required Map<String, dynamic> form,
    required int pageNumber,
    required Map<int, page_model.Page> computedPages,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _form = form,
        _pageNumber = pageNumber,
        _computedPages = computedPages..[pageNumber] = page_model.Page.fromJson(form['pages'][pageNumber.toString()]),
        _db = db,
        _auth = auth;

  @override
  State<FormScreenAdmin> createState() => _FormScreenAdminState();
}

class _FormScreenAdminState extends State<FormScreenAdmin> {

  late page_model.Page _page;

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

      elements.add(TextFormField(
        readOnly: true,
      ));

    }else if(element.runtimeType == Selection){

      Selection selElement = element as Selection;

      List<Widget> selections = [];

      if(selElement.numSelections == 1){

        for(String key in selElement.selections.keys){
          if(key != "other"){
            selections.add(
                RadioListTile<String>(
                  title: Text(key),
                  value: key,
                  groupValue: "",
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
                ),
                value: "other",
                groupValue: "",
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
                  value: false,
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
                ),
                value: false,
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