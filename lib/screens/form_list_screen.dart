import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin/form_screen_admin.dart';
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

// TODO Make some kind of Widget factory for pages
class _FormListScreenState extends State<FormListScreen> {

  @override
  void initState() {

    super.initState();
    widget._auth.authStateChanges().asBroadcastStream().listen((User? user) {

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
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Forms"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'View profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          )
        ],
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