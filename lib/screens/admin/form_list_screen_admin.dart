import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:who_app/screens/admin/form_screen_admin.dart';
import '../form_screen.dart';

class FormListScreenAdmin extends StatefulWidget {

  const FormListScreenAdmin({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _db = db,
       _auth = auth;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  State<FormListScreenAdmin> createState() => _FormListScreenAdminState();
}

class _FormListScreenAdminState extends State<FormListScreenAdmin> {

  @override
  void initState() {

    super.initState();
    widget._auth.authStateChanges().asBroadcastStream().listen((User? user) async {

      if (user == null || (await widget._db.collection('users').doc(user.uid).get()).data()!['role'] != 'admin') {

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
        title: Text("Forms (Admin)"),
        actions: [
          TextButton(
            onPressed: () async {
              widget._auth.signOut();
            },
            child: const Text('Log out'),
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
                        builder: (context) => FormScreenAdmin(
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