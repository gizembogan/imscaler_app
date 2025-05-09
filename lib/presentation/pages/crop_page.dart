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
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          statusBarColor: Colors.deepPurple.shade700,
          backgroundColor: Colors.deepPurple.shade50,
          hideBottomControls: true,
          activeControlsWidgetColor: Colors.white,
          cropFrameColor: Colors.black,
          cropGridColor: Colors.white24,
          dimmedLayerColor: Colors.black54,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioLockEnabled: true,
          rotateButtonsHidden: true,
          resetButtonHidden: false,
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (cropped == null) {
      _pickAndCropImage();
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                          builder: (_) =>
                              PreparingPhotoPage(imageData: _croppedImage!),
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
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _croppedImage = null;
                      });
                      _pickAndCropImage();
                    },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
