import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:who_app/screens/admin/form_screen_admin.dart';
import 'package:who_app/screens/admin/submissions_screen_admin.dart';
import '../form_screen.dart';
import 'form_editing_screen.dart';

class FormListScreenAdmin extends StatefulWidget {

  const FormListScreenAdmin({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth,
    bool? testing
  }) : _db = db,
       _auth = auth,
       _testing = testing ?? false;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  final bool _testing;

  @override
  State<FormListScreenAdmin> createState() => _FormListScreenAdminState();
}

class _FormListScreenAdminState extends State<FormListScreenAdmin> {

  late StreamSubscription<User?> _subscription;

  @override
  void initState() {

    super.initState();
    _subscription = widget._auth.authStateChanges().asBroadcastStream().listen((User? user) async {

      if (!widget._testing && (user == null || (await widget._db.collection('users').doc(user.uid).get()).data()!['role'] != 'admin')) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not authorized to access this page. Please sign in.'),
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.of(context).popUntil((route) => false);
        Navigator.pushNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {

    _subscription.cancel();
    super.dispose();
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

          if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: Text("No forms have been created yet.",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    )
                )
              ],
            );
          }

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
                        builder: (context) => SubmissionsScreenAdmin(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
              MaterialPageRoute(
                builder: (context) => FormEditingScreen(
                  db: widget._db,
                  auth: widget._auth,
                ),
              )
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}