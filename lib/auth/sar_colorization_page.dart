// sar_colorization_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class SARColorizationPage extends StatefulWidget {
  @override
  _SARColorizationPageState createState() => _SARColorizationPageState();
}

class _SARColorizationPageState extends State<SARColorizationPage> {
  File? _inputImage;
  File? _outputImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Pick an input image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _inputImage = File(pickedFile.path);
        _outputImage = null; // Clear any previous output
      });
    }
  }

  // Send the image to the Flask server and fetch the output image
  Future<void> _processImage() async {
    if (_inputImage == null) return;

    setState(() {
      _isLoading = true;
    });

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.0.195:5000/colorize'), // Replace with Flask server URL
    );
    request.files.add(
      await http.MultipartFile.fromPath('image', _inputImage!.path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      final dir = await getTemporaryDirectory();
      final outputFile = File('${dir.path}/output_image.png');
      await outputFile.writeAsBytes(bytes);

      setState(() {
        _outputImage = outputFile;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process the image.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Navigate to a full-screen view of the image
  void _viewImage(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('View Image'),
            backgroundColor: Colors.black,
          ),
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: FileImage(image),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SAR Colorization'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Upload and Colorize SAR Image',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                _inputImage == null
                    ? Text(
                        'No input image selected.',
                        style: TextStyle(color: Colors.white),
                      )
                    : GestureDetector(
                        onTap: () => _viewImage(_inputImage!),
                        child: Image.file(
                          _inputImage!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                  ),
                  child: Text(
                    'Pick Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _processImage,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.greenAccent),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Colorize',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                ),
                SizedBox(height: 20),
                _outputImage == null
                    ? Text(
                        'No output image available.',
                        style: TextStyle(color: Colors.white),
                      )
                    : GestureDetector(
                        onTap: () => _viewImage(_outputImage!),
                        child: Image.file(
                          _outputImage!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
