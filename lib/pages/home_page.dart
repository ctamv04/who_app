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
import 'form_page.dart';

class HomePage extends StatefulWidget {

  const HomePage({
    super.key,
    required FirebaseFirestore db
  }) : _db = db;

  final FirebaseFirestore _db;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Forms"),
      ),
      body: StreamBuilder(
        stream: widget._db.collection("forms").snapshots(),
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {

              final form = snapshot.data?.docs[index].data();
              return ListTile(
                title: Text(form?['title']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormPage(
                        form: form,
                        pageNumber: 1,
                        db: widget._db
                      ),
                    ),
                  );
                },
              );
            }
          );
        }
      ),
    );
  }
}