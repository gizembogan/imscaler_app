import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:imscaler/services/onnx_model_service.dart'; // Import the service
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_page.dart';
import 'presentation/pages/upload_page.dart';
import 'presentation/pages/splash_screen.dart'; // Import the splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // No need to await model loading here, SplashScreen will handle it
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ImScaler',
      // Start with SplashScreen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // SplashScreen route
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/upload': (context) => const UploadPage(),
      },
    );
  }
}
