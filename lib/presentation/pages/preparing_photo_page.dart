import 'dart:typed_data';
// import 'dart:io'; // No longer needed for Platform checks here
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle; // No longer loading model here
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:imscaler/services/onnx_model_service.dart'; // Import the service
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
  // OrtSession? _session; // Session now managed by OnnxModelService
  // OrtEnv? _env; // Env now managed by OnnxModelService
  final OnnxModelService _modelService = OnnxModelService(); // Get instance of the service

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
    // _loadModelAndProcessImage(); // Model is loaded by SplashScreen, just process image
    _initProcess();
  }

  Future<void> _initProcess() async {
    // Ensure model is loaded before processing
    if (!_modelService.isModelLoaded) {
      print("PreparingPhotoPage: Model not loaded yet by service. Waiting or handling error...");
      // Attempt to load if not loaded, though SplashScreen should handle this.
      // This is a fallback.
      await _modelService.loadModel(); 
      if (!_modelService.isModelLoaded) { // Check again after attempting to load
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Model not loaded. Please restart app.")));
         if (mounted) Navigator.pop(context);
         return;
      }
    }
    await _processImage();
  }

  // Future<void> _loadModelAndProcessImage() async { // This method is removed/refactored
  // }

  Future<void> _processImage() async {
    print("PreparingPhotoPage: Starting _processImage with onnxruntime...");
    
    if (_modelService.session == null || !_modelService.isModelLoaded) {
      print("PreparingPhotoPage: ONNX Session from service is not initialized. Cannot process image.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Model not available. Please try again.")));
        Navigator.pop(context);
      }
      return;
    }

    print("PreparingPhotoPage: Decoding image data (onnxruntime)...");
    img.Image? originalImage = img.decodeImage(widget.imageData);
    if (originalImage == null) {
      print("PreparingPhotoPage: Failed to decode image (onnxruntime). originalImage is null.");
      if (mounted) Navigator.pop(context);
      return;
    }
    print("PreparingPhotoPage: Image decoded. Width: ${originalImage.width}, Height: ${originalImage.height}");

    print("PreparingPhotoPage: Resizing image to 96x96 (onnxruntime)...");
    img.Image resizedImage = img.copyResize(originalImage, width: 96, height: 96);
    print("PreparingPhotoPage: Image resized. Width: ${resizedImage.width}, Height: ${resizedImage.height}");

    print("PreparingPhotoPage: Preparing input tensor (onnxruntime)...");
    
    final inputShape = [1, 3, 96, 96]; // NCHW
    final inputData = Float32List(inputShape[0] * inputShape[1] * inputShape[2] * inputShape[3]);
    int bufferIndex = 0;
    for (int c = 0; c < inputShape[1]; c++) { // Channels
      for (int h = 0; h < inputShape[2]; h++) { // Height
        for (int w = 0; w < inputShape[3]; w++) { // Width
          var pixel = resizedImage.getPixel(w, h);
          double normalizedValue;
          if (c == 0) { normalizedValue = (pixel.rNormalized - 0.485) / 0.229; } // R
          else if (c == 1) { normalizedValue = (pixel.gNormalized - 0.456) / 0.224; } // G
          else { normalizedValue = (pixel.bNormalized - 0.406) / 0.225; } // B
          inputData[bufferIndex++] = normalizedValue;
        }
      }
    }

    final inputOrt = OrtValueTensor.createTensorWithDataList(inputData, inputShape);
    
    final String inputName = "input"; 
    final inputs = {inputName: inputOrt};
    
    print("PreparingPhotoPage: Input tensor prepared for ONNX. Name: $inputName, Shape: $inputShape");

    print("PreparingPhotoPage: Output tensor will be inferred by ONNX runtime.");

    print("PreparingPhotoPage: Running inference with onnxruntime...");
    try {
      final runOptions = OrtRunOptions();
      // Use session from the service
      final List<OrtValue?>? outputs = await _modelService.session!.runAsync(runOptions, inputs); 
      
      if (outputs == null || outputs.isEmpty || outputs[0] == null) {
        throw Exception("ONNX model output is null or empty.");
      }
      final OrtValue outputNonNullOrtValue = outputs[0]!;

      // Removed problematic type and typeInfo checks for onnxruntime 1.4.1
      // final String outputName = _session!.outputNames.isNotEmpty ? _session!.outputNames[0] : 'unknown_output';
      // print("PreparingPhotoPage: Inference completed. Output tensor name: $outputName");

      // ASSUME output shape for this version, as dynamic retrieval API is unclear/failing.
      // The critical validation will be the total number of elements in the output data.
      final List<int> outputShape = [1, 3, 512, 512]; // Expected NCHW
      
      // Get data from OrtValue.value
      final dynamic rawOutputData = outputNonNullOrtValue.value;

      if (rawOutputData == null) {
        throw Exception("Output tensor data from OrtValue.value is null.");
      }
      // UPDATED: Check for the new expected type
      if (rawOutputData is! List<List<List<List<double>>>>) {
        throw Exception("Output tensor data (OrtValue.value) is not List<List<List<List<double>>>>. Actual type: ${rawOutputData.runtimeType}");
      }
      // UPDATED: Cast to the correct nested list type
      final List<List<List<List<double>>>> outputData = rawOutputData;
      
      print("PreparingPhotoPage: Processing output tensor. Assumed Shape: $outputShape, Data runtimeType: ${outputData.runtimeType}");

      // This check now primarily verifies that our hardcoded/assumed shape matches the expectation for further processing.
      if (outputShape.length != 4 || outputShape[0] != 1 || outputShape[1] != 3 || outputShape[2] != 512 || outputShape[3] != 512) {
        throw Exception("Unexpected output tensor shape: $outputShape. Expected NCHW [1, 3, 512, 512]");
      }
      
      // Verify the structure of the nested list based on the shape
      if (outputData.length != outputShape[0] || 
          outputData[0].length != outputShape[1] || 
          outputData[0][0].length != outputShape[2] || 
          outputData[0][0][0].length != outputShape[3]) {
        throw Exception("Output data structure does not match expected shape [1, 3, 512, 512]. Actual dimensions: [${outputData.length}, ${outputData[0].length}, ${outputData[0][0].length}, ${outputData[0][0][0].length}]");    
      }

      img.Image outputImage = img.Image(width: 512, height: 512);
      
      // UPDATED: Access data from the nested list structure (NCHW)
      // N (batch) is outputData[0]
      // C (channels) is outputData[0][c]
      // H (height) is outputData[0][c][y]
      // W (width) is outputData[0][c][y][x]
      final List<List<double>> rChannel = outputData[0][0]; // Red channel data (512x512)
      final List<List<double>> gChannel = outputData[0][1]; // Green channel data (512x512)
      final List<List<double>> bChannel = outputData[0][2]; // Blue channel data (512x512)

      for (int y = 0; y < 512; y++) {
        for (int x = 0; x < 512; x++) {
          double rValue = rChannel[y][x];
          double gValue = gChannel[y][x];
          double bValue = bChannel[y][x];

          double r = (rValue * 0.229 + 0.485) * 255.0;
          double g = (gValue * 0.224 + 0.456) * 255.0;
          double b = (bValue * 0.225 + 0.406) * 255.0;
          outputImage.setPixelRgba(x, y, r.clamp(0, 255).toInt(), g.clamp(0, 255).toInt(), b.clamp(0, 255).toInt(), 255);
        }
      }
      print("PreparingPhotoPage: Output image processed (onnxruntime).");

      if (mounted) {
        print("PreparingPhotoPage: Setting state with processed image (onnxruntime)...");
        setState(() {
          _processedImage = Uint8List.fromList(img.encodePng(outputImage));
        });
        print("PreparingPhotoPage: State set. _processedImage is ${_processedImage == null ? 'null' : 'not null'}");

        if (_processedImage != null) {
            print("PreparingPhotoPage: Scheduling navigation to PhotoPage (onnxruntime)...");
            Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
                print("PreparingPhotoPage: Navigating to PhotoPage now (onnxruntime)...");
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PhotoPage(imageData: _processedImage!),
                    ),
                );
            } else {
                print("PreparingPhotoPage: Navigation to PhotoPage aborted, widget not mounted anymore (onnxruntime).");
            }
            });
        } else {
          print("PreparingPhotoPage: _processedImage is null, cannot navigate (onnxruntime).");
        }
      } else {
        print("PreparingPhotoPage: Widget not mounted after processing, cannot set state or navigate (onnxruntime).");
      }

    } catch (e, s) {
      print("PreparingPhotoPage: Error during inference with onnxruntime: $e");
      print("PreparingPhotoPage: Stack trace for inference error: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ONNX Inference error: $e")));
        Navigator.pop(context);
      }
      return;
    } finally {
      // Release OrtValue objects if they are not automatically managed or if runAsync created them.
      // inputOrt.release(); // OrtValueTensor.createTensorWithDataList might not need manual release
      // outputOrtValue.release(); // If created by runAsync, it might be managed by the list.
      // Check package docs for OrtValue lifecycle.
    }
    
    print("PreparingPhotoPage: Finished _processImage with onnxruntime.");
  }

  @override
  void dispose() {
    _controller.dispose();
    // _session?.release(); // Service handles session lifecycle
    // _env?.release(); // Service handles env lifecycle
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
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
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
                      // if (_processedImage == null && _session != null) // Check service model loaded state
                      if (_processedImage == null && _modelService.isModelLoaded && _modelService.session != null)
                        const CircularProgressIndicator()
                      // else if (_session == null) // Check service model loaded state
                      else if (!_modelService.isModelLoaded)
                         Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text("Loading Model...", style: TextStyle(color: Colors.white.withOpacity(0.7)))
                          ],
                         ),
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
