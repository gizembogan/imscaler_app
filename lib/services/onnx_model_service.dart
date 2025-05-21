import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';

class OnnxModelService {
  OrtSession? _session;
  OrtEnv? _env;
  bool _isModelLoaded = false;
  static final OnnxModelService _instance = OnnxModelService._internal();

  factory OnnxModelService() {
    return _instance;
  }

  OnnxModelService._internal();

  OrtSession? get session => _session;
  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel() async {
    if (_isModelLoaded) {
      print("OnnxModelService: Model already loaded.");
      return;
    }
    try {
      print("OnnxModelService: Starting to load ONNX model...");
      _env = OrtEnv.instance;
      final sessionOptions = OrtSessionOptions();
      print("OnnxModelService: Session options created.");

      final modelBytes = await rootBundle.load('assets/models/model_int8_static.onnx');
      print("OnnxModelService: Model asset loaded. Byte length: ${modelBytes.lengthInBytes}");
      
      _session = OrtSession.fromBuffer(modelBytes.buffer.asUint8List(), sessionOptions);
      _isModelLoaded = true;
      print("OnnxModelService: ONNX Session created successfully.");
    } catch (e, s) {
      _isModelLoaded = false;
      print("OnnxModelService: Failed to load ONNX model. Error: $e");
      print("OnnxModelService: Stack trace: $s");
      // Optionally, rethrow or handle more gracefully
    }
  }

  void dispose() {
    _session?.release();
    _env?.release();
    _isModelLoaded = false;
    print("OnnxModelService: Resources released.");
  }
}
