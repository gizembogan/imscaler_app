import 'dart:typed_data';
import 'dart:io'; // Import for Platform
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // Added for rootBundle
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
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
  OrtSession? _session;
  OrtEnv? _env;

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
    try {
      print("PreparingPhotoPage: Starting _loadModelAndProcessImage with onnxruntime...");
      
      _env = OrtEnv.instance;
      final sessionOptions = OrtSessionOptions();
      print("PreparingPhotoPage: Session options created. Will use default provider.");

      // Load model from assets as bytes
      print("PreparingPhotoPage: About to load model asset 'assets/models/model_int8_static.onnx'...");
      final modelBytes = await rootBundle.load('assets/models/model_int8_static.onnx');
      print("PreparingPhotoPage: Model asset loaded. Byte length: ${modelBytes.lengthInBytes}");
      
      print("PreparingPhotoPage: About to create ONNX session from buffer...");
      _session = OrtSession.fromBuffer(modelBytes.buffer.asUint8List(), sessionOptions);
      print("PreparingPhotoPage: ONNX Session created successfully with onnxruntime.");

      // Optionally, print input/output names and shapes
      // final inputNames = _session!.inputNames;
      // final outputNames = _session!.outputNames;
      // print("Input names: $inputNames");
      // print("Output names: $outputNames");
      // if (inputNames.isNotEmpty) {
      //   // For version 1.4.1, getting detailed input type info might be limited.
      //   // Focus on names and assume shape based on model knowledge.
      // }

      setState(() {}); // To reflect model loaded state via _session != null
      await _processImage();
    } catch (e, s) {
      print("PreparingPhotoPage: Failed to load model or process image with onnxruntime. Error: $e");
      print("PreparingPhotoPage: Stack trace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load ONNX model: $e")));
        Navigator.pop(context);
      }
    }
    print("PreparingPhotoPage: Finished _loadModelAndProcessImage with onnxruntime.");
  }

  Future<void> _processImage() async {
    print("PreparingPhotoPage: Starting _processImage with onnxruntime...");
    if (_session == null) {
      print("PreparingPhotoPage: ONNX Session is not initialized. Cannot process image.");
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
    // CRITICAL: Replace 'serving_default_input:0' with your model's actual input name.
    // You can find this using Netron or by inspecting _session!.inputNames.
    final String inputName = "input"; // Changed to use the name from ONNX export
    final inputs = {inputName: inputOrt};
    // Corrected: Print the inputShape variable directly
    print("PreparingPhotoPage: Input tensor prepared for ONNX. Name: $inputName, Shape: $inputShape");

    print("PreparingPhotoPage: Output tensor will be inferred by ONNX runtime.");

    print("PreparingPhotoPage: Running inference with onnxruntime...");
    try {
      final runOptions = OrtRunOptions();
      // Corrected: Changed type to List<OrtValue?>?
      final List<OrtValue?>? outputs = await _session!.runAsync(runOptions, inputs); 
      
      // CRITICAL: Access output by index.
      // Assuming the desired output is the first one. Verify with Netron or _session!.outputNames.
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
    _session?.release();
    _env?.release();
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
                      if (_processedImage == null && _session != null) // Show progress only while processing and model is loaded
                        const CircularProgressIndicator()
                      else if (_session == null) // Show loading indicator for model
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
