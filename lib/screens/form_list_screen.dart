import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:who_app/screens/submissions_screen.dart';
import 'form_screen.dart';

class FormListScreen extends StatefulWidget {

  const FormListScreen({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _db = db,
       _auth = auth;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  State<FormListScreen> createState() => _FormListScreenState();
}

class _FormListScreenState extends State<FormListScreen> {

  @override
  Widget build(BuildContext context) {

    List<Widget> actions = [
      TextButton(
        child: Text("Sign in"),
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
      )
    ];
    if(widget._auth.currentUser != null){
      actions = [
        IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'View profile',
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        )
      ];
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Forms"),
        actions: actions
      ),
      body: StreamBuilder(
        stream: widget._db.collection("forms").snapshots(),
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {

              final doc = snapshot.data?.docs[index];
              if(doc != null){

                final formTitle = doc.data()['title'];
                return ListTile(
                  title: Text(formTitle),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmissionsScreen(
                          key: UniqueKey(),
                          formId: doc.id,
                          formTitle: formTitle,
                          db: widget._db,
                          auth: widget._auth,
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