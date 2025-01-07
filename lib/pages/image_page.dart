import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'drawing_page.dart';




class ImageUploadPage extends StatefulWidget {

  const ImageUploadPage({
    super.key,
    required FirebaseFirestore db
  }) : _db = db;

  final FirebaseFirestore _db;
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _image;
  String? imageurl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Navigate to the Drawing Screen
  void navigateToDrawingScreen() async {
    if (_image == null) return;

    final drawnImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingPage(imageFile: _image!),
      ),
    );

    if (drawnImage != null) {
      setState(() {
        _image = drawnImage;
      });
    }
  }

  Future<void> uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();     
      final storageRef = FirebaseStorage.instance.ref().child('images/$fileName');

      // Upload the file
      await storageRef.putFile(_image!).whenComplete( (){
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          content: Text('Upload successful!'))
          ,
        );
    });

      imageurl = await storageRef.getDownloadURL();
      print(imageurl);


    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload a Image')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : ElevatedButton(
              onPressed: pickImage,
              child: Text('Select a Image'),
            ),
            const SizedBox(height: 16),
            
            const SizedBox(height: 16),
            if (_image != null)
              ElevatedButton(
                onPressed: navigateToDrawingScreen,
                child: const Text('Draw on Image'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : uploadImage,
              child: _isUploading ? CircularProgressIndicator() : Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}
