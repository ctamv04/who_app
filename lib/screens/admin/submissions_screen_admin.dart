import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:who_app/screens/admin/form_editing_screen.dart';
import 'package:who_app/screens/admin/form_screen_admin.dart';

class SubmissionsScreenAdmin extends StatefulWidget {

  const SubmissionsScreenAdmin({
    super.key,
    required String formId,
    required String formTitle,
    required FirebaseFirestore db,
    required FirebaseAuth auth,
    bool? testing
  }) : _formId = formId,
        _formTitle = formTitle,
       _db = db,
       _auth = auth,
       _testing = testing ?? false;

  final String _formId;

  final String _formTitle;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  final bool _testing;

  @override
  State<SubmissionsScreenAdmin> createState() => _SubmissionsScreenAdminState();
}

class _SubmissionsScreenAdminState extends State<SubmissionsScreenAdmin> {

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
        title: Text("${widget._formTitle}: Submissions"),
      ),
      body: StreamBuilder(
        stream: widget._db.collection("filled_forms").where('form_id', isEqualTo: widget._formId).snapshots(),
        builder: (context, snapshot) {

          if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: Text("No forms of this type have been submitted yet.",
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

                final form = doc.data();
                final tit = '${doc.id.substring(15)}: ${form['uid']}, ${form['date']}';
                return ListTile(
                  title: Text('${doc.id.substring(15)}: ${form['uid']}, ${form['date']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormScreenAdmin(
                          formId: widget._formId,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          final form = (await widget._db.collection('forms').doc(widget._formId).get()).data()!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormEditingScreen(
                formId: widget._formId,
                form: form,
                pageNumber: 1,
                db: widget._db,
                auth: widget._auth,
              ),
            ),
          );
        },
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}