import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'form_screen.dart';

class FormListScreen extends StatefulWidget {

  const FormListScreen({
    super.key,
    required FirebaseFirestore db
  }) : _db = db;

  final FirebaseFirestore _db;

  @override
  State<FormListScreen> createState() => _FormListScreenState();
}

// TODO Make some kind of Widget factory for pages
class _FormListScreenState extends State<FormListScreen> {

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
              if(form != null){
                return ListTile(
                  title: Text(form['title']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormScreen(
                            key: UniqueKey(),
                            form: form,
                            pageNumber: 1,
                            computedPages: {},
                            db: widget._db
                        ),
                      ),
                    );
                  },
                );
              }
            }
          );
        }
      ),
    );
  }
}