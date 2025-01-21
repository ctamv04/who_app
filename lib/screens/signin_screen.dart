import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

                    await widget._auth.signInWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);

                    context.go('/forms');
                  } on FirebaseAuthException catch (e) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Wrong email/password combination'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('Sign in'),
              )
            ]
        )
      )
    );
  }
}