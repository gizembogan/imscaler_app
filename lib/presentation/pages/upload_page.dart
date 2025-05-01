import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/profile_icon.dart';
import 'preparing_photo_page.dart';
import '../widgets/background_container.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Uint8List? _selectedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = _centerCropToSquare(bytes);
      });
    }
  }

  Uint8List _centerCropToSquare(Uint8List bytes) {
    // cropping will be done with image packet!
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ProfileIconButton(),
        ],
      ),
      body: BackgroundContainer(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Center(
              child: Text(
                "ImScaler",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _selectedImage == null
                    ? ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    "UPLOAD A PHOTO",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: MemoryImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                      ),
                      child: const Text(
                        "Pick Another",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreparingPhotoPage(imageData: _selectedImage!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
