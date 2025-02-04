import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth,
    bool? testing
  }) : _db = db, _auth = auth, _testing = testing ?? false;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  final bool _testing;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _positionController = TextEditingController();

  final TextEditingController _institutionController = TextEditingController();

  late PhoneNumber _phoneNumber;

  final TextEditingController _cityController = TextEditingController();

  final TextEditingController _countryController = TextEditingController();

  final TextEditingController _unitController = TextEditingController();

  late StreamSubscription<User?> _subscription;

  @override
  void initState() {

    super.initState();
    _subscription = widget._auth.authStateChanges().asBroadcastStream().listen((User? user) async {

      if (!widget._testing && (user == null || (await widget._db.collection('users').doc(user.uid).get()).data()!['role'] != 'user')) {

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

    return FutureBuilder(
      future: widget._db.collection('users').doc(widget._auth.currentUser!.uid).get(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final userData = snapshot.data!.data()!;

        _nameController.text = userData['name'] as String;
        _positionController.text = userData['position'] as String;
        _institutionController.text = userData['institution'] as String;
        _cityController.text = userData['city'] as String;
        _countryController.text = userData['country'] as String;
        _unitController.text = userData['unit'] as String;

        TextEditingController emailController = TextEditingController();
        emailController.text = widget._auth.currentUser!.email!;

        if (_isEditing){
          return Scaffold(
              appBar: AppBar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  actions: [
                    TextButton(
                      onPressed: () {
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
                                  Row(
                                      children: [
                                        Text('Full name:  ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                            child: TextFormField(
                                              controller: _nameController,
                                            )
                                        )
                                      ]),
                                  Row(
                                      children: [
                                        Text('Position:  ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                            child: TextFormField(
                                              controller: _positionController,
                                            )
                                        )
                                      ]),
                                  Row(children: [
                                    Text('Institution:  ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          controller: _institutionController,
                                        )
                                    )
                                  ]),
                                  Row(children: [
                                    Text('Email:  ',
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
                                            _phoneNumber = PhoneNumber(isoCode: "GR");
                                          }else{
                                            _phoneNumber = snapshot2.data!;
                                          }

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
                                  ),
                                  Row(children: [
                                    Text('City:  ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          controller: _cityController,
                                        )
                                    )
                                  ]),
                                  Row(children: [
                                    Text('Country:  ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          controller: _countryController,
                                        )
                                    )
                                  ]),
                                  Row(children: [
                                    Text('Unit of measurement:  ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          controller: _unitController,
                                        )
                                    )
                                  ])
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
                                        'name': _nameController.text,
                                        'position': _positionController.text,
                                        'institution': _institutionController.text,
                                        'phone': _phoneNumber.phoneNumber!,
                                        'city': _cityController.text,
                                        'country': _countryController.text,
                                        'unit': _unitController.text,
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
                              Text('Full name:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['name'] as String)
                            ]),
                            Row(children: [
                              Text('Position:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['position'] as String)
                            ]),
                            Row(children: [
                              Text('Institution:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['institution'] as String)
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
                            ]),
                            Row(children: [
                              Text('City:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['city'] as String)
                            ]),
                            Row(children: [
                              Text('Country:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['country'] as String)
                            ]),
                            Row(children: [
                              Text('Unit of measurement:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(userData['unit'] as String)
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