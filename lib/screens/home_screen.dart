import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'form_screen.dart';

class HomeScreen extends StatelessWidget {

  const HomeScreen({
    super.key,
    required FirebaseFirestore db,
    required FirebaseAuth auth
  }) : _db = db, _auth = auth;

  final FirebaseFirestore _db;

  final FirebaseAuth _auth;

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.currentUser == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/forms');
      }
    });

    return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        )
    );
  }
}