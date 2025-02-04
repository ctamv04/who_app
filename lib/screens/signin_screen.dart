import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {

  const LoginScreen({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _db = db, _auth = auth;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 250,
                      width: 250,
                      child: Image.asset(
                        "assets/who_logo.png",
                      ),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Email",
                      ),
                      controller: _emailController,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Password",
                      ),
                      controller: _passwordController,
                      obscureText: true,
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

                        try {

                          await widget._auth.signInWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
                        } on FirebaseAuthException catch (e) {

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Wrong email/password combination'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }

                        if((await widget._db.collection('users').doc(widget._auth.currentUser!.uid).get()).data()!['role'] == 'user'){
                          Navigator.pushReplacementNamed(context, '/forms');
                        }else{
                          Navigator.pushReplacementNamed(context, '/forms_admin');
                        }
                      },
                      child: const Text('Sign in',
                        style: TextStyle(
                            color: Colors.white
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: Text("Create an account")
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/forms');
                            },
                            child: Text("Continue as guest")
                        )
                      ],
                    )
                  ]
              )
          ),
        )
      )
    );
  }
}