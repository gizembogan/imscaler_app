import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/background_container.dart';
import '../widgets/profile_icon.dart';
import 'upload_page.dart';

class PhotoPage extends StatefulWidget {
  final Uint8List imageData;
  const PhotoPage({super.key, required this.imageData});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveProcessedImage() async {
    final data = widget.imageData;
    if (Platform.isAndroid &&
        !(await Permission.manageExternalStorage.request().isGranted)) return;
    if (!Platform.isAndroid &&
        !(await Permission.photos.request().isGranted)) return;

    setState(() => _isSaving = true);

    final dir = (await getExternalStorageDirectory()) ??
        Directory('/storage/emulated/0/DCIM/Camera');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final file = File(
      '${dir.path}/imscaler_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(data);

    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _isSaved = false);
  }

  void _openFullScreenImage() {
    final display = widget.imageData;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Image.memory(
                  display,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [ProfileIconButton()],
      ),
      body: BackgroundContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Center(
              child: Text(
                'ImScaler',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _openFullScreenImage,
                    child: widget.imageData.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(
                              widget.imageData,
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const SizedBox(
                            width: 250,
                            height: 250,
                            child: Center(
                                child: Text("Image not available",
                                    style: TextStyle(color: Colors.white))),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UploadPage()),
                              (route) => false,
                        ),
                      ),
                      const SizedBox(width: 40),
                      IconButton(
                        icon: _isSaving
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.bookmark_border,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed:
                        _isSaving ? null : () => _saveProcessedImage(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isSaved) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text(
                        'SAVED TO GALLERY!',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
