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

class _PreparingPhotoPageState extends State<PreparingPhotoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoPage(imageData: widget.imageData),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShimmerText() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              transform: GradientTranslation(_shimmerAnimation.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: const Text(
        "WE ARE PREPARING YOUR PHOTO !!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildShimmerText(),
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

class GradientTranslation extends GradientTransform {
  final double slidePercent;

  GradientTranslation(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
