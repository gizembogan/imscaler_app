
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'photo_page.dart';
import '../widgets/background_container.dart';

class PreparingPhotoPage extends StatefulWidget {
  final Uint8List imageData;
  const PreparingPhotoPage({super.key, required this.imageData});

  @override
  _PreparingPhotoPageState createState() => _PreparingPhotoPageState();
}

class _PreparingPhotoPageState extends State<PreparingPhotoPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PhotoPage(imageData: widget.imageData)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "ImScaler",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: MemoryImage(widget.imageData),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const CircularProgressIndicator(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "WE ARE PREPARING YOUR PHOTO !!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
