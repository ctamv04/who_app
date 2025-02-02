import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:who_app/screens/form_screen_readonly.dart';
import 'form_screen.dart';

class SubmissionsScreen extends StatefulWidget {

  const SubmissionsScreen({
    super.key,
    required String formId,
    required String formTitle,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _formId = formId,
        _formTitle = formTitle,
       _db = db,
       _auth = auth;

  final String _formId;

  final String _formTitle;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {

  @override
  Widget build(BuildContext context) {

    final user = widget._auth.currentUser;
    return FutureBuilder(
        future: user == null ? getGuestId() : Future.value("signed in"),
        builder: (context, snapshot1) {

          if (!snapshot1.hasData) {
            return CircularProgressIndicator();
          }

          Stream<QuerySnapshot<Map<String, dynamic>>>? stream;
          if(snapshot1.data == "signed in"){
            stream = widget._db.collection("filled_forms").where('uid', isEqualTo: widget._auth.currentUser!.uid).where('form_id', isEqualTo: widget._formId).snapshots();
          }else{
            stream = widget._db.collection("filled_forms").where('uid', isEqualTo: snapshot1.data).where('form_id', isEqualTo: widget._formId).snapshots();
          }

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text("${widget._formTitle}: Submissions"),
            ),
            body: StreamBuilder(
                stream: stream,
                builder: (context, snapshot2) {

                  if(snapshot2.hasData && snapshot2.data!.docs.isEmpty){
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("You haven't submitted any forms of this type yet.",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        )
                      ],
                    );
                  }

                  return ListView.builder(
                      itemCount: snapshot2.data?.docs.length,
                      itemBuilder: (context, index) {

                        final doc = snapshot2.data?.docs[index];
                        if(doc != null){

                          final form = doc.data();
                          return ListTile(
                            title: Text('${doc.id.substring(15)}: ${form['date']}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FormScreenReadOnly(
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
            floatingActionButton: FloatingActionButton(
              onPressed: () async {

                final form = (await widget._db.collection('forms').doc(widget._formId).get()).data()!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormScreen(
                      key: UniqueKey(),
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
              child: const Icon(Icons.add),
            ),
          );
        }
    );
  }

  Future<String> getGuestId() async {

    final path = (await getApplicationDocumentsDirectory()).path;
    final file = File('$path/guest_id.txt');

    String userId = "";
    if(await file.exists()){
      userId = await file.readAsString();
    }else {
      userId = Uuid().v4();
      await file.writeAsString(userId);
    }

    return userId;
  }
}