import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {

  const SignupScreen({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _db = db, _auth = auth;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _passwordConfirmController = TextEditingController();

  bool _emptyName = false;

  bool _passwordsDontMatch = false;

  bool _passwordTooShort = false;

  bool _noUpLowCharacter = false;

  bool _noSpecialCharacter = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
              width: 500,
              padding: const EdgeInsets.all(40.0),
              child: Column(
                  spacing: 10.0,
                  children: [
                    Container(
                      height: 250,
                      width: 250,
                      child: Image.asset(
                        "assets/who_logo.png",
                      ),
                    ),
                    Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Full name",
                          ),
                          controller: _nameController,
                          onChanged: (value) {
                            setState(() {
                              _emptyName = _nameController.text.isEmpty;
                            });
                          },
                        ),
                        Visibility(
                          visible: _emptyName,
                          child: Text("- Name can't be empty",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Email",
                      ),
                      controller: _emailController,
                    ),
                    Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Password",
                          ),
                          controller: _passwordController,
                          obscureText: true,
                          onChanged: (value) {

                            setState(() {
                              _noSpecialCharacter = !RegExp("[^a-zA-Z0-9]").hasMatch(value);
                              _passwordTooShort = (value.length < 8);
                              _noUpLowCharacter = !RegExp("[A-Z]").hasMatch(value) || !RegExp("[a-z]").hasMatch(value);
                            });
                          },
                        ),
                        Visibility(
                          visible: _passwordTooShort,
                          child: Text("- Password must be at least 8 characters long",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _noUpLowCharacter,
                          child: Text("- Password must contain at least one lowercase and uppercase character",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _noSpecialCharacter,
                          child: Text("- Password must have at least one special character.",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Confirm password",
                          ),
                          controller: _passwordConfirmController,
                          obscureText: true,
                          onChanged: (value) {
                            setState(() {
                              _passwordsDontMatch = (value != _passwordController.text);
                            });
                          },
                        ),
                        Visibility(
                          visible: _passwordsDontMatch,
                          child: Text("- Passwords do not match",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(
                            BorderSide(
                                color: Colors.white,
                                width: 2
                            )
                        ),
                      ),
                      onPressed: () async {

                        if(_emptyName || _noUpLowCharacter || _passwordTooShort || _noSpecialCharacter || _passwordsDontMatch){
                          return;
                        }

                        try {

                          final credential = await widget._auth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);

                          await widget._db.collection('users').doc(credential.user!.uid).set({
                            'role': 'user',
                            'name': _nameController.text,
                            'phone': '',
                            'institution': '',
                            'position': '',
                            'city': '',
                            'country': '',
                            'unit': '',
                          });

                          Navigator.pushReplacementNamed(context, '/login');
                        } on FirebaseAuthException catch (e) {

                          String warning = "An error has occured. Please try again later.";
                          switch(e.code){
                            case 'invalid-email':
                              warning = "Invalid email";
                            case 'email-already-in-use':
                              warning = "Email is already in use.";
                          }

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(warning),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('Sign up',
                        style: TextStyle(
                            color: Colors.white
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text("Do you already have an account? Log in")
                    )
                  ]
              )
          ),
        )
      )
    );
  }
}