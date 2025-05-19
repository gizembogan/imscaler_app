import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart'; // Reverted to tflite_flutter
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
  Uint8List? _processedImage;
  Interpreter? _interpreter; // Reverted to Interpreter
  // bool _modelLoaded = false; // Using _interpreter null check

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
    _loadModelAndProcessImage();
  }

  Future<void> _loadModelAndProcessImage() async {
    print("PreparingPhotoPage: Starting _loadModelAndProcessImage with tflite_flutter...");
    try {
      print("PreparingPhotoPage: Loading model from asset 'assets/models/upscaler.tflite' using tflite_flutter...");
      
      // For tflite_flutter, we might need to explicitly add Select TF Ops delegate
      final options = InterpreterOptions();
      // Attempting to add SelectTfOpsDelegate if available/needed.
      // This delegate might need to be added natively if not available directly in Dart.
      // The tflite_flutter plugin documentation should be checked for how to best enable Select TF Ops.
      // For now, we rely on the gradle dependency `org.tensorflow:tensorflow-lite-select-tf-ops`
      // to make the ops available to the runtime.

      _interpreter = await Interpreter.fromAsset(
        'assets/models/upscaler.tflite',
        options: options,
      );
      print("PreparingPhotoPage: Interpreter created with tflite_flutter.");
      // _interpreter.allocateTensors(); // Usually not needed if run is called immediately

      // Verify input and output tensor details
      print("Input tensors: ${_interpreter!.getInputTensors()}");
      print("Output tensors: ${_interpreter!.getOutputTensors()}");

      setState(() {}); // To reflect model loaded state via _interpreter != null
      await _processImage();
    } catch (e, s) {
      print("PreparingPhotoPage: Failed to load model or process image with tflite_flutter. Error: $e");
      print("PreparingPhotoPage: Stack trace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load model: $e")));
        Navigator.pop(context);
      }
    }
    print("PreparingPhotoPage: Finished _loadModelAndProcessImage with tflite_flutter.");
  }

  Future<void> _processImage() async {
    print("PreparingPhotoPage: Starting _processImage with tflite_flutter...");
    if (_interpreter == null) {
      print("PreparingPhotoPage: Interpreter is not initialized (tflite_flutter). Cannot process image.");
      return;
    }

    print("PreparingPhotoPage: Decoding image data (tflite_flutter)...");
    img.Image? originalImage = img.decodeImage(widget.imageData);
    if (originalImage == null) {
      print("PreparingPhotoPage: Failed to decode image (tflite_flutter). originalImage is null.");
      if (mounted) Navigator.pop(context);
      return;
    }
    print("PreparingPhotoPage: Image decoded. Width: ${originalImage.width}, Height: ${originalImage.height}");

    print("PreparingPhotoPage: Resizing image to 96x96 (tflite_flutter)...");
    img.Image resizedImage = img.copyResize(originalImage, width: 96, height: 96);
    print("PreparingPhotoPage: Image resized. Width: ${resizedImage.width}, Height: ${resizedImage.height}");

    print("PreparingPhotoPage: Preparing input tensor (tflite_flutter)...");
    // Input shape [1, 96, 96, 3] as per model requirements
    var input = List.generate(1,
        (_) => List.generate(96,
            (j) => List.generate(96, 
                (k) {
                  var pixel = resizedImage.getPixel(k, j);
                  // Normalization as per the Python script
                  return [
                    (pixel.rNormalized - 0.485) / 0.229,
                    (pixel.gNormalized - 0.456) / 0.224,
                    (pixel.bNormalized - 0.406) / 0.225
                  ];
                }
            )
        )
    , growable: false);
    // print("Input tensor sample value: ${input[0][0][0]}");

    // Output shape [1, 512, 512, 3]
    var output = List.generate(1, 
        (_) => List.generate(512, 
            (_) => List.generate(512, 
                (_) => List.filled(3, 0.0, growable: false),
            growable: false),
        growable: false)
    );
    print("PreparingPhotoPage: Output tensor initialized. Shape: [1, 512, 512, 3]");

    print("PreparingPhotoPage: Running inference with tflite_flutter...");
    try {
      _interpreter!.run(input, output);
      print("PreparingPhotoPage: Inference completed with tflite_flutter.");

      // --- Output Processing for tflite_flutter ---
      // Output is directly in the `output` variable with the specified shape.
      // Denormalize and convert to image
      print("PreparingPhotoPage: Processing output tensor...");
      img.Image outputImage = img.Image(width: 512, height: 512);
      for (int y = 0; y < 512; y++) {
        for (int x = 0; x < 512; x++) {
          double r = (output[0][y][x][0] * 0.229 + 0.485) * 255.0;
          double g = (output[0][y][x][1] * 0.224 + 0.456) * 255.0;
          double b = (output[0][y][x][2] * 0.225 + 0.406) * 255.0;
          outputImage.setPixelRgba(x, y, r.clamp(0, 255).toInt(), g.clamp(0, 255).toInt(), b.clamp(0, 255).toInt(), 255);
        }
      }
      print("PreparingPhotoPage: Output image processed (tflite_flutter).");

      if (mounted) {
        print("PreparingPhotoPage: Setting state with processed image (tflite_flutter)...");
        setState(() {
          _processedImage = Uint8List.fromList(img.encodePng(outputImage));
        });
        print("PreparingPhotoPage: State set. _processedImage is ${ _processedImage == null ? 'null' : 'not null' }");

        if (_processedImage != null) {
            print("PreparingPhotoPage: Scheduling navigation to PhotoPage (tflite_flutter)...");
            Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
                print("PreparingPhotoPage: Navigating to PhotoPage now (tflite_flutter)...");
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PhotoPage(imageData: _processedImage!),
                    ),
                );
            } else {
                print("PreparingPhotoPage: Navigation to PhotoPage aborted, widget not mounted anymore (tflite_flutter).");
            }
            });
        } else {
          print("PreparingPhotoPage: _processedImage is null, cannot navigate (tflite_flutter).");
        }
      } else {
        print("PreparingPhotoPage: Widget not mounted after processing, cannot set state or navigate (tflite_flutter).");
      }

    } catch (e, s) {
      print("PreparingPhotoPage: Error during inference with tflite_flutter: $e");
      print("PreparingPhotoPage: Stack trace for inference error: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inference error: $e")));
        Navigator.pop(context);
      }
      return;
    }
    
    print("PreparingPhotoPage: Finished _processImage with tflite_flutter.");
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter?.close(); // Close the interpreter
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
                            image: MemoryImage(_processedImage ?? widget.imageData), // Show processed or original
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      if (_processedImage == null) // Show progress only while processing
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
