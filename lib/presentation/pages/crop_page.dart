import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'preparing_photo_page.dart';
import '../widgets/background_container.dart';
import '../widgets/profile_icon.dart';

class CropPage extends StatefulWidget {
  const CropPage({Key? key}) : super(key: key);

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  Uint8List? _croppedImage;

  @override
  void initState() {
    super.initState();
    _pickAndCropImage();
  }

  Future<void> _pickAndCropImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
      Navigator.pop(context);
      return;
    }

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Kareyi Seç',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          statusBarColor: Colors.deepPurple.shade700,
          backgroundColor: Colors.deepPurple.shade50,

          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,

          cropFrameColor: Colors.red,
          cropGridColor: Colors.white24,
          dimmedLayerColor: Colors.black54,
          activeControlsWidgetColor: Colors.white,
        ),
        IOSUiSettings(
          title: 'Kareyi Seç',
          aspectRatioLockEnabled: true,
          rotateButtonsHidden: true,
          resetButtonHidden: false,
          doneButtonTitle: 'Tamam',
          cancelButtonTitle: 'İptal',
        ),
      ],
    );

    if (cropped == null) {
      Navigator.pop(context);
      return;
    }

    final bytes = await cropped.readAsBytes();
    setState(() => _croppedImage = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_croppedImage == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [ProfileIconButton()],
        ),
        body: BackgroundContainer(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [ProfileIconButton()],
      ),
      body: BackgroundContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 20),
            // Kırpılmış kare gösterimi
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: MemoryImage(_croppedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreparingPhotoPage(imageData: _croppedImage!),
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
    );
  }
}
