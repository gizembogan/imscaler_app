import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/profile_icon.dart';
import 'upload_page.dart';
import '../widgets/background_container.dart';

class PhotoPage extends StatefulWidget {
  final Uint8List imageData;
  const PhotoPage({super.key, required this.imageData});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  bool _isSaved = false;

  Future<void> _saveImage() async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/saved_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(widget.imageData);

    final galleryDir = Directory('/storage/emulated/0/DCIM/Camera');
    if (!galleryDir.existsSync()) {
      galleryDir.createSync(recursive: true);
    }
    await file.copy('${galleryDir.path}/imscaler_${DateTime.now().millisecondsSinceEpoch}.jpg');

    if (!mounted) return;

    setState(() {
      _isSaved = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    setState(() {
      _isSaved = false;
    });
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
            const SizedBox(height: 20),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: MemoryImage(widget.imageData),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const UploadPage()),
                          (Route<dynamic> route) => false,
                    );
                  },
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 30),
                  onPressed: _saveImage,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isSaved) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "SAVED TO GALLERY!",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
