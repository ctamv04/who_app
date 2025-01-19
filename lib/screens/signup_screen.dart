import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {

  const SignUpScreen({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _db = db, _auth = auth;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  State<SignUpScreen> createState() => _SignUpScreenScreenState();
}

// TODO Make some kind of Widget factory for pages
class _SignUpScreenScreenState extends State<SignUpScreen> {

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/who_logo.png",
                scale: 0.05,
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
                onPressed: () async {

                  try {

                    widget._auth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);

                    Navigator.pushReplacementNamed(context, '/forms');
                  } on FirebaseAuthException catch (e) {

                    var text = "";
                    if (e.code == 'email-already-in-use') {
                      text = "There already exists an account with this email address.";
                    } else if (e.code == 'too-many-requests') {
                      text = "Too many requests. Please try again later.";
                    }else{
                      text = "An error has occured. Please try again later.";
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(text),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  widget._auth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
                },
                child: const Text('Sign up'),
              )
            ]
        )
      )
    );
  }
}