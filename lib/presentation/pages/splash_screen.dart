import 'package:flutter/material.dart';
import 'package:imscaler/services/onnx_model_service.dart';
import 'login_page.dart'; // Assuming LoginPage is your main screen after splash

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load the ONNX model
    await OnnxModelService().loadModel();

    // After model is loaded (or attempt has been made), navigate to the main app screen
    // You might want to add error handling here if model loading fails critically
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Or your main app page
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading Model..."),
          ],
        ),
      ),
    );
  }
}
