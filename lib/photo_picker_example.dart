import 'dart:io'; // File için
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPickerExample extends StatefulWidget {
  @override
  _PhotoPickerExampleState createState() => _PhotoPickerExampleState();
}

class _PhotoPickerExampleState extends State<PhotoPickerExample> {
  XFile? _image;

  Future<bool> requestPermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      var result = await Permission.photos.request();
      return result.isGranted;
    }
    return true;
  }

  Future<void> pickImage() async {
    bool granted = await requestPermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf izni verilmedi!')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fotoğraf Seçme Örneği')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('Henüz fotoğraf seçilmedi.')
                : Image.file(
              File(_image!.path),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Fotoğraf Seç'),
            ),
          ],
        ),
      ),
    );
  }
}

