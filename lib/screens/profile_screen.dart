import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _db = db, _auth = auth;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();

  final TextEditingController _lastNameController = TextEditingController();

  late PhoneNumber _phoneNumber;

  @override
  void initState() {

    super.initState();
    widget._auth.authStateChanges().asBroadcastStream().listen((User? user) async {

      if (user == null || (await widget._db.collection('users').doc(user.uid).get()).data()!['role'] != 'user') {

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

    return FutureBuilder(
      future: widget._db.collection('users').doc(widget._auth.currentUser!.uid).get(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final userData = snapshot.data!.data()!;

        _firstNameController.text = userData['first_name'] as String;
        _lastNameController.text = userData['last_name'] as String;
        TextEditingController emailController = TextEditingController();
        emailController.text = widget._auth.currentUser!.email!;

        if (_isEditing){
          return Scaffold(
              appBar: AppBar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  actions: [
                    TextButton(
                      onPressed: () async {
                        widget._auth.signOut();
                      },
                      child: const Text('Log out'),
                    )
                  ]
              ),
              body: Form(
                  key: _formKey,
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text('First name:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          controller: _firstNameController,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "First name can't be empty";
                                            }
                                            return null;
                                          },
                                        )
                                    )
                                  ]),
                                  Row(children: [
                                    Text('Last name:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          controller: _lastNameController,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Last name can't be empty";
                                            }
                                            return null;
                                          },
                                        )
                                    )
                                  ]),
                                  Row(children: [
                                    Text('Email:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          controller: emailController,
                                          readOnly: true,
                                        )
                                    )
                                  ]),
                                  FutureBuilder(
                                        future: PhoneNumber.getRegionInfoFromPhoneNumber(userData['phone'] as String),
                                        builder: (context, snapshot2) {

                                          if (!snapshot2.hasData) {
                                            return CircularProgressIndicator();
                                          }

                                          _phoneNumber = snapshot2.data!;

                                          return InternationalPhoneNumberInput(
                                            selectorConfig: SelectorConfig(
                                              selectorType: PhoneInputSelectorType.BOTTOM_SHEET
                                            ),
                                            hintText: 'Phone',
                                            initialValue: _phoneNumber,
                                            onInputChanged: (number) {
                                              _phoneNumber = number;
                                            },
                                          );
                                        }
                                  )
                                ]
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.cancel),
                                  tooltip: 'Cancel',
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check_circle),
                                  tooltip: 'Confirm',
                                  onPressed: () async {

                                    if (_formKey.currentState!.validate()) {

                                      snapshot.data!.reference.update({
                                        'first_name': _firstNameController.text,
                                        'last_name': _lastNameController.text,
                                        'phone': _phoneNumber.phoneNumber!
                                      });
                                      setState(() {
                                        _isEditing = false;
                                      });
                                    }
                                  },
                                )
                              ],
                            )
                          ]
                      )
                  )
              )
          );
        }

        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                actions: [
                  TextButton(
                    onPressed: () async {
                      widget._auth.signOut();
                    },
                    child: const Text('Log out'),
                  )
                ]
            ),
            body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('First name:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['first_name'] as String)
                            ]),
                            Row(children: [
                              Text('Last name:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['last_name'] as String)
                            ]),
                            Row(children: [
                              Text('Email:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(widget._auth.currentUser!.email!)
                            ]),
                            Row(children: [
                              Text('Phone:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['phone'] as String)
                            ])
                          ]
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Edit info',
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      )
                    ]
                )
            )
        );
      }
    );
  }
}